module Rulebow

  ##
  # Rulesets provides namespace isolation for facts, rules and methods.
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

      @scripts  = []
      @rules    = []
      @docs     = []
      @requires = []

      @name, @chain = parse_ruleset_name(name)

      @session = system.session

      @watchlist = WatchList.new(:ignore=>system.ignore)

      module_eval(&block) if block
    end

    # Ruleset name
    attr :name

    # Description of ruleset.
    attr :docs

    # Chain or dependencies.
    attr :chain

    # Session object can be used to passing information around between rulesets.
    attr :session

    # Rule scripts.
    attr :scripts

    # Array of defined facts.
    #attr :facts

    # Array of defined rules.
    attr :rules

    # Files to watch for this ruleset.
    attr :watchlist

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

    # Add paths to be watched.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def watch(*globs)
      @watchlist.accept(globs) unless globs.empty?
      @watchlist
    end

    # Replace paths to be watched.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def watch!(*globs)
      @watchlist.accept!(globs)
    end

    # Add paths to be ignored in file rules.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def ignore(*globs)
      @watchlist.ignore(globs) unless globs.empty?
    end

    # Replace globs in ignore list.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def ignore!(*globs)
      @watchlist.ignore!(globs)
    end

    # Define a dependency chain.
    #
    # Returns [Array<Symbol>]
    def chain=(*rulesets)
      @chain = rulesets.map{ |b| b.to_sym }
    end

    # Provide a ruleset description.
    #
    # Returns [String]
    def desc(description)
      @docs << description
    end

    # Define a rule. Rules are procedures that are tiggered 
    # by logical facts.
    #
    # Examples
    #   rule :rdocs? do |files|
    #     sh "rdoc --output doc/rdoc " + files.join(" ")
    #   end
    #
    # TODO: Allow for an expression array that conjoins them with AND logic.
    #
    # Returns [Rule]
    def rule(expression, &block)
      case expression
      when Hash
        expression.each do |fact, task|
          fact = define_fact(fact)
          task = define_task(task)
          @rules << Rule.new(fact, &task)
        end
      else
        fact = define_fact(expression)
        @rules << Rule.new(fact, &block)
      end

      #rule = Rule.new(@_facts, get_rule_options, &procedure)
      #@rules << rule
      #clear_rule_options

      return @rules
    end

    # Defines a fact. Facts define conditions that are used to trigger
    # rules. Named facts are defined as methods to ensure that only one fact
    # is ever defined for a given name. Calling fact again with the same name
    # as a previously defined fact will redefine the condition of that fact.
    #
    # Examples
    #   fact :no_doc? do
    #     File.directory?('doc')
    #   end
    #
    # Returns the name if name and condition is given. [Symbol]
    # Returns a fact in only name or condition is given. [Fact]
    def fact(name=nil, &condition)
      if name && conditon
        define_method(name) do
          Fact.new(&condition)  # TODO: maybe we don't really need the cache after all
        end
        name
      else
        define_fact(name || condition)
      end
    end

    # Will probably be deprecated.
    alias :state :fact

    # Define a file fact.
    #
    # TODO: Probably will add this back & limit `fact` so it can't be used for file facts.
    #
    # Returns [FileFact]
    #def file(patterns, &coerce)
    #  FileFact.new(patterns, &coerce)
    #end

    # Convenince method for defining environment variable facts.
    #
    # Examples
    #   rule env('PATH'=>/foo/) => :dosomething
    #
    # Returns [Fact]
    def env(name_to_pattern)
      Fact.new do
        name_to_pattern.any? do |name, re|
          re === ENV[name.to_s]  # or `all?` instead?
        end
      end
    end

    # TODO: Private rulesets that can't be run from the CLI?
    #       Hmmm... maybe instead it can work like rake, if docs is empty
    #       it can't be run from the command line.
    #
    #def privatize
    #  @privatized = true
    #end

    # Issue notification.
    #
    # Returns nothing.
    def notify(message, options={})
      title = options.delete(:title) || 'Rulebow Notification'
      Notify.notify(title, message.to_s, options)
    end

    # Any requires made within a ruleset will not be actually 
    # required until a rule is run.
    #
    # TODO: This feature has yet to be implemented.
    #
    # Returns nothing.
    def require(feature=nil)
      @requires << feature if feature
      @requires
    end

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

    # Define a fact.
    #
    # Returns [Fact]
    def define_fact(fact)
      case fact
      when Fact
        fact
      when String, Regexp
        @watchlist.accept(fact)
        FileFact.new(fact)
      when Symbol
        Fact.new{ send(fact) }
      when true, false, nil
        Fact.new{ fact }
      else #when Proc
        Fact.new(&fact)
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


