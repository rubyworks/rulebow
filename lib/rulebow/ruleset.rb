module Rulebow

  ##
  # Rulesets provides namespace isolation for states, rules and methods.
  #
  class Ruleset < Module

    # Instantiate new ruleset.
    #
    # Arguments
    #    system - The system to which this ruleset belongs. [System]
    #    name   - Name of the ruleset.
    #
    # Yields the script defining the ruleset rules.
    def initialize(system, name, &block)
      extend ShellUtils
      extend system
      extend self

      @scripts = []
      @rules   = []
      @docs    = []

      @name, @chain = parse_ruleset_name(name)

      @session = system.session

      @ignore = Ignore.new(system.ignore)

      #@states = []

      module_eval(&block) if block
    end

    #
    #def update(chain, &block)
    #  @chain = chain if chain
    #  module_eval(&block) if block
    #end

    # Ruleset name
    attr :name

    #
    attr :docs

    # Toolchain (dependencies)
    attr :chain

    # Current session.
    attr :session

    # Rule scripts.
    attr :scripts

    # Array of defined states.
    attr :states

    # Array of defined rules.
    attr :rules

    # Import from another file, or glob of files, relative to project root.
    #
    # TODO: Should importing be relative to the importing file? Currently
    #       it is relative to the project root.
    #
    # Returns nothing.
    def import(*globs)
      globs.each do |glob|
        #if File.relative?(glob)
        #  dir = Dir.pwd  #session.root #File.dirname(caller[0])
        #  glob = File.join(dir, glob)
        #end
        Dir[glob].each do |file|
          next unless File.file?(file)  # add warning
          next if @scripts.include?(file)
          @scripts << file
          module_eval(File.read(file), file)
        end
      end
    end

    # Add paths to be ignored in file rules.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def ignore(*globs)
      @ignore.concat(globs) unless globs.empty?
      @ignore
    end

    # Replace globs in ignore list.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def ignore!(*globs)
      @ignore.replace(globs)
      @ignore
    end

    # Define a dependency chain.
    #
    # Returns [Array<Symbol>]
    def chain=(*rulesets)
      @chain = rulesets.map{ |b| b.to_sym }
    end

    # Define a named state. States define conditions that are used to trigger
    # rules. Named states are kept in a hash table to ensure that only one state
    # is ever defined for a given name. Calling state again with the same name
    # as a previously defined state will redefine the condition of that state.
    #
    # Examples
    #   state :no_doc? do
    #     File.directory?('doc')
    #   end
    #
    # Returns nil if state name is given. [nil]
    # Returns State in no name is given. [State]
    def state(name, &condition)
      define_method(name) do
        #@states[name.to_sym] ||= State.new(&condition)
        State.new(&condition)  # TODO: maybe we don't really need the cache after all
      end
    end

    # Define a file state.
    #
    # Returns [FileState]
    #def file(patterns, &coerce)
    #  FileState.new(patterns, &coerce)
    #end

    # Defines an environment state.
    #
    # Examples
    #   rule env('PATH'=>/foo/) => :dosomething
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
    #   rule :rdocs? do |files|
    #     sh "rdoc --output doc/rdoc " + files.join(" ")
    #   end
    #
    # Returns [Rule]
    def rule(expression, &block)
      case expression
      when Hash
        expression.each do |state, task|
          state = define_state(state)
          task  = define_task(task)
          @rules << Rule.new(state, &task)
        end
      else
        state = define_state(expression)
        @rules << Rule.new(state, &block)
      end

      #rule = Rule.new(@_states, get_rule_options, &procedure)
      #@rules << rule
      #clear_rule_options

      return @rules
    end

    # Set rule description. The next rule defined will get the most
    # recently defined description attached to it.
    #
    # Returns [String]
    def desc(description)
      @docs << description
    end

    # TODO: Private rulesets that can't be run from the CLI?
    #
    #def private(*methods)
    #  @_priv = true
    #  super(*methods)   # TODO: why doesn't this work as expected?
    #end

    # Issue notification.
    #
    # Returns nothing.
    def notify(message, options={})
      title = options.delete(:title) || 'Rulebow Notification'
      Notify.notify(title, message.to_s, options)
    end

    # Check a name state.
    #
    # Returns [Array,Boolean]
    #def state?(name, *args)
    #  @states[name.to_sym].call(*args)
    #end

    # Better inspection string.
    def inspect
      if chain.empty?
        "#<Ruleset #{name}>"
      else
        "#<Ruleset #{name} " + chain.join(' ') + ">"
      end
    end

    # TODO: Good idea?
    def to_s
      name.to_s
    end

  private

    # Define a state.
    #
    # Returns [State]
    def define_state(state)
      case state
      when State
        state
      when String, Regexp
        FileState.new(state)
      when Symbol
        State.new{ send(state) }
      when true, false, nil
        State.new{ state }
      else #when Proc
        State.new(&state)
      end
    end

    #
    def define_task(task)
      case task
      when Symbol
        Proc.new do |*a|
          meth = method(task)
          if meth.arity == 0
            meth.call
          else
            meth.call(*a)
          end
        end
      else
        task.to_proc
      end
    end

    # Parse out a ruleset's name from it's ruleset dependencies.
    #
    # name - ruleset name
    #
    # Returns [Array]
    def parse_ruleset_name(name)
      if Hash === name
        raise ArgumentError if name.size > 1       
        list = [name.values].flatten.map{ |b| b.to_sym }
        name = name.keys.first
      else
        list = []
      end
      return name.to_sym, list
    end
  end

end


