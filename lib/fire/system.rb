module Fire

  # Master system instance.
  #
  # Returns [System]
  #def self.system
  #  @system ||= System.new
  #end

  ##
  # A fire system stores defined states and rules.
  #
  # TODO: There are some namespace issues with this implementation.
  #       We don't necessarily want a rule block to be able to
  #       call #rule.
  #
  class System < Module

    # Instantiate new system.
    #
    # Arguments
    #    scripts - List of rule scripts to import.
    #
    # Options
    #    digest - Instance of Digest class. [Digest]]
    #
    def initialize(*scripts)
      extend self
      extend ShellUtils

      options = (Hash === scripts.last ? scripts.pop : {})

      @scripts = []
      @rules   = []
      @states  = {}

      @digest  = options[:digest] || Digest.new
      @session = OpenStruct.new

      import *scripts
    end

    # Current session.
    attr :session

    # Rule scripts.
    attr :scripts

    # File digest.
    attr :digest

    # Array of defined states.
    attr :states

    # Array of defined rules.
    attr :rules

    # Import from another file, or glob of files, relative to project root.
    #
    # TODO: Should importing be relative the importing file?
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
          #instance_eval(File.read(file), file)
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
      digest.ignore.replace(globs)
      digest.ignore
    end

    # Append globs to ignore list.
    #
    # globs - List of file globs. [Array<String>]
    #
    # Returns [Array<String>]
    def ignore!(*globs)
      digest.ignore.concat(globs)
      digest.ignore
    end

    # Define a named state. States define conditions that are used to trigger
    # rules. Named states are kept in a hash table to ensure that only one state
    # is ever defined for a given name. Calling state again with the same name
    # as a previously defined state will redefine the condition of that state.
    #
    # Examples
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
      FileState.new(pattern, digest)
    end

    # Define an environment state.
    #
    # Examples
    #   env('PATH'=>/foo/)
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
    # Returns [Rule]
    def rule(state, &procedure)
      case state
      when String, Regexp
        state = file(state)
      when Symbol
        # TODO: Is this really the best idea?
        #@states[state.to_sym]
      end
      rule = Rule.new(state, get_rule_options, &procedure)
      @rules << rule
      clear_rule_options
      rule
    end

    # Check a name state.
    #
    # Returns [Array,Boolean]
    def state?(name, *args)
      @states[name.to_sym].call(*args)
    end

    # Set rule description. The next rule defined will get the most
    # recently defined description attached to it.
    #
    # Returns [String]
    def desc(description)
      @_desc = description
    end

    # Set rule book(s). If block is used, then rules are private
    # to the book and will not be run via master execution.
    #
    # Yields private book rules.
    # Returns nothing.
    def book(*names)
      if block_given?
        @_book, @_priv = names, true
        yield
        @_book, @_priv = nil, nil
      else
        @_book = names
      end
      return names.size  # this is a trick to repurose private
    end

    def private(method=nil)
      return super() if method.nil?
      return @_priv = true if Fixnum === method
      super(method)
    end

    # Issue notification.
    #
    # Returns nothing.
    def notify(message, options={})
      title = options.delete(:title) || 'Fire Notification'
      Notify.notify(title, message.to_s, options)
    end

  private

    def get_rule_options
      { :desc => @_desc, :book=>@_book, :private=>@_priv }
    end

    def clear_rule_options
      @_desc = nil
      @_book = nil
      @_priv = nil
    end

  end

end
