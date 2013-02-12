require 'ostruct'
require 'notify'

require 'fire/shellutils'
require 'fire/rule'
require 'fire/state'
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
    #       we don't necessarily want a rule block to be able to call #rule.

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

    # Import from another file, or glob of files, relative to project root.
    #
    # @todo Should importing be relative the importing file?
    # @return nothing
    def import(*globs)
      globs.each do |glob|
        #if File.relative?(glob)
        #  dir = Dir.pwd  #session.root #File.dirname(caller[0])
        #  glob = File.join(dir, glob)
        #end
        Dir[glob].each do |file|
          next unless File.file?(file)
          #instance_eval(File.read(file), file)
          module_eval(File.read(file), file)
        end
      end
    end

    # Add paths to be ignored in file rules.
    def ignore(*globs)
      @ignore.concat(globs.flatten)
      @ignore
    end

    # Define a named state. States define conditions that are used to trigger
    # rules. Named states are kept in a hash table to ensure that only one state
    # is ever defined for a given name. Calling state again with the same name
    # as a previously defined state will redefine the condition of that state.
    #
    # @example
    #   state :no_rdocs? do
    #     files = Dir.glob('lib/**/*.rb')
    #     FileUtils.uptodate?('doc', files) ? files : false
    #   end
    #
    # Returns nil if state name is given. [nil]
    # Returns State in no name is given. [State]
    def state(name=nil, &condition)
      if name
        if condition
          @states[name.to_sym] = condition
          define_method(name) do |*args|
            state = @states[name.to_sym]
            State.new{ states[name.to_sym].call(*args) }
          end
        else
          raise ArgumentError
        end
      else
        State.new{ condition.call(*args) }
      end
    end

    # Define a file state.
    #
    # Returns [FileState]
    def file(pattern)
      FileState.new(pattern, digest, ignore)
    end

    # Define an environment state.
    #
    # Examples
    #     env('PATH'=>/foo/)
    #
    # Returns [State]
    def env(name_to_pattern)
      State.new do
        name_to_pattern.any? do |name, re|
          re === ENV[name.to_s]  # or `all?` instead?
        end
      end
    end

    # Define a rule. Rules are procedures that are tiggered 
    # by logical states.
    #
    # Examples
    #   rule no_rdocs do |files|
    #     sh "rdoc --output doc/rdoc " + files.join(" ")
    #   end
    #
    def rule(state, &procedure)
      state, todo = parse_arrow(state)

      case state
      when String, Regexp
        file_rule(state, :todo=>todo, &procedure)
      when Symbol
        # TODO: Is this really the best idea?
        #@states[state.to_sym]
      else
        @rules << Rule.new(state, :todo=>todo, &procedure)
      end
    end

    #
    # Check a name state.
    #
    def state?(name, *args)
      @states[name.to_sym].call(*args)
    end

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

    # Define a command line task. A task is special type of rule that
    # is triggered when the command line tool is invoked with
    # the name of the task.
    #
    # Tasks are an isolated set of rules and suppress the activation of
    # all other rules not specifically given as prerequisites.
    #
    #   task :rdoc do
    #     trip no_rdocs
    #   end
    #
    # Returns [Task]
    def task(name_and_state, &procedure)
      name, todo = parse_arrow(name_and_state)
      task = Task.new(name, :todo=>todo, :desc=>@_desc, &procedure)
      @tasks[name.to_sym] = task
      @_desc = nil
      task
    end

    #
    # Issue notification.
    #
    def notify(message, options={})
      title = options.delete(:title) || 'Fire Notification'
      Notify.notify(title, message.to_s, options)
    end

  private

    # Split a hash argument into it's key and value pair.
    # The hash is expected to have only one entry. If the argument
    # is not a hash then returns the argument and an empty array.
    # 
    # Raises an [ArgumetError] if the hash has more than one entry.
    #
    # Returns key and value. [Array]
    def parse_arrow(argument)
      case argument
      when Hash
        raise ArgumentError if argument.size > 1
        head, tail = *argument.to_a.first
        return head, Array(tail)
      else
        return argument, []
      end
    end

    # TODO: pass `self` to FileState instead of digest and igonre ?

    # Define a file rule. A file rule is a rule with a specific state
    # based on changes in files.
    #
    # @example
    #   file_rule 'test/**/case_*.rb' do |files|
    #     sh "ruby-test " + files.join(" ")
    #   end
    #
    # Returns nothing.
    def file_rule(pattern, options={}, &procedure)
      state = FileState.new(pattern, digest, ignore)
      @rules << Rule.new(state, options, &procedure)
    end

  end

end
