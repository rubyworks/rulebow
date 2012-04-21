require 'ostruct'
require 'fire/shellutils'
require 'fire/state'
require 'fire/rule'
require 'fire/logic'
require 'fire/file_logic'
require 'fire/task'
#require 'fire/rulefile'
require 'fire/digest'
#require 'fire/rc'

module Fire

  #
  # Master system instance.
  #
  def self.system
    @system ||= System.new
  end

  # System stores states and rules.
  class System < Module

    # Instantiate new system.
    #
    def initialize(ignore=nil, *files)
      extend self

      extend ShellUtils

      @ignore  = ignore || []
      @states  = []
      @rules   = []
      @files   = files
      @tasks   = {}

      @digest  = Digest.new

      @session = OpenStruct.new

      files.each do |file|
        instance_eval(File.read(file), file)
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
      define_method(name) do |*args, &block|
        Logic.new{ state.call(*args, &block) }
      end
      @states << state
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
      @rules << Rule.new(logic, &procedure)
    end

    # TODO: do we want to rename #file to #path so we might support
    # Rake-style file tasks in the future?

    # Define a file rule. A file rule is a rule with a specific state logic
    # based on changes in files.
    #
    # @example
    #   file 'test/**/case_*.rb' do |files|
    #     sh "ruby-test " + files.join(" ")
    #   end
    #
    def file(pattern, &procedure)
      logic = FileLogic.new(pattern, digest)
      @rules << Rule.new(logic, &procedure)
    end

    #
    def trip(state)
      puts "STATE: #{state}"
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

    #def eval(script)
    #  @evaluator ||= Rulefile.new(self)
    #  @evaluator.eval(script)
    #end
  end

end
