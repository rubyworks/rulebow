require 'ostruct'
require 'notify'

require 'fire/shellutils'
require 'fire/state'
require 'fire/rule'
require 'fire/logic'
require 'fire/task'
require 'fire/digest'
#require 'fire/rulefile'

module Fire

  #
  # Master system instance.
  #
  def self.system
    @system ||= System.new
  end

  # System stores states and rules.
  class System < Module

    # TODO: there are some namespace issues to deal with here.
    #       we don't necessarily want a task block to be able to call #task.

    # Instantiate new system.
    #
    def initialize(options={})
      extend self
      extend ShellUtils

      @ignore  = Array(options[:ignore] || [])
      @files   = Array(options[:files]  || [])

      @rules   = []
      @states  = {}
      @tasks   = {}

      @digest  = Digest.new
      @session = OpenStruct.new

      @files.each do |file|
        module_eval(File.read(file), file)
      end
    end

    # Current session.
    attr :session

    # Array of defined states.
    attr :states

    # Array of defined rules.
    attr :rules

    # Mapping of defined tasks.
    attr :tasks

    # File digest.
    attr :digest

    #
    # Import from another file, or glob of files, relative to current working directory.
    #
    def import(glob)
      Dir[glob].each do |file|
        next unless File.file?(file)
        instance_eval(File.read(file), file)
      end
    end

    # Set paths to be ignored in file rules.
    def ignore(*globs)
      @ignore.concat(globs.flatten)
      @ignore
    end

    # TODO: I think @states has to be a hash, how can there be more than one by the same name?

    # Define a named state. States define logic methods that 
    # can be used by rules.
    #
    # @example
    #   state :no_rdocs do
    #     files = Dir.glob('lib/**/*.rb')
    #     FileUtils.uptodate?('doc', files) ? files : false
    #   end
    #
    def state(name, &condition)
      state = State.new(name, &condition)
      define_method(name) do |*args|
        Logic.new{ state.call(*args) }
      end
      @states[name.to_sym] = state
    end

    # Define a rule. Rules are procedures that are tiggered 
    # by logical states.
    #
    # @example
    #   rule no_rdocs do |files|
    #     sh "rdoc --output doc/rdoc " + files.join(" ")
    #   end
    #
    def rule(logic, &procedure)
      case logic
      when String, Regexp
        file_rule(logic, &procedure)
      when Symbol
      else
        @rules << Rule.new(logic, &procedure)
      end
    end

    #
    # Check a state.
    #
    def state?(name, *args)
      @states[name.to_sym].call(*args)
    end

    # TODO: do we want to rename #file to #path so we might support
    # Rake-style file tasks in the future? Or maybe #change ?

    # TODO: pass `self` to FileLogic instead of digest and igonre ?

    # Define a file rule. A file rule is a rule with a specific state logic
    # based on changes in files.
    #
    # @example
    #   file_rule 'test/**/case_*.rb' do |files|
    #     sh "ruby-test " + files.join(" ")
    #   end
    #
    def file_rule(pattern, &procedure)
      logic = FileLogic.new(pattern, digest, ignore)
      @rules << Rule.new(logic, &procedure)
    end

    # Force given states to true and run all rules associated to them.
    #
    # @todo Is it possible to trigger only associated rules?
    #def trip(*states)
    #  puts "STATE: #{state}"
    #end

    #
    # Run a task.
    #
    def run(task_name) #, *args)
      tasks[task_name.to_sym].invoke #call(*args)
    end

    # Set task description. The next task defined will get the most
    # recently defined description attached to it.
    def desc(description)
      @_desc = description
    end

    # TODO: command line interfaces
    #   Could we support tasks with specific ARGV signitures?
    #   e.g. cli(args, :opt1=>Intger, :opt2=>String, :opt3=>FalseClass)

    # Define a command line task. A task is special type of rule that
    # is triggered when the `ou` command line tool is invoked with
    # the name of the task.
    #
    # Tasks are an isolated set of rules and suppress the activation of
    # all other rules not specifically given as task pre-requisites.
    #
    #   task :rdoc do
    #     trip no_rdocs
    #   end
    #
    def task(name_and_logic, &procedure)
      case name_and_logic
      when Hash
        name, pre = *name_and_logic.to_a.first
      else
        name, pre = name_and_logic, []
      end

      task = Task.new(name, self, :pre=>pre, :desc=>@_desc, &procedure)

      #logic = Logic.new do
      #  ARGV.first == name.to_s
      #end
      #@rules << Rule.new(logic, &task)

      @tasks[name.to_sym] = task

      @_desc = nil
    end

    #
    # Issue notification.
    #
    def notify(message, options={})
      title = options.delete(:title) || 'Fire Notification'
      Notify.notify(title, message.to_s, options)
    end

    #def eval(script)
    #  @evaluator ||= Rulefile.new(self)
    #  @evaluator.eval(script)
    #end
  end

end
