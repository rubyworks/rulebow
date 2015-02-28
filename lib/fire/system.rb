module Fire

  # Master system instance.
  #
  # Returns [System]
  #def self.system
  #  @system ||= System.new
  #end

  ##
  #
  class System < Module

    RULEBOOK_GLOB = "{,.,_}{R,r}ulebook{,.rb}"

    # Initialize new System instance.
    #
    def initialize(options={})
      extend self
      extend ShellUtils

      @root   = options[:root]   || Dir.pwd
      @ignore = options[:ignore] || Ignore.new

      @rulebook   = options[:rulebook]
      @state_file = options[:statefile]

      @session = OpenStruct.new

      @scripts  = []
      @rules    = []
      #@states  = []

      @digests  = {}
      @rulesets = {}

      import(*rulebook)
    end

    # Project's root directory. [String]
    attr :root

    # Session variables. [Hash]
    attr :session

    # Digests [Hash]
    attr :digests

    # Rulesets indexed by name. [Hash]
    attr :rulesets

    # Rulebook file.
    def rulebook
      @rulebook ||= Dir[File.join(root, RULEBOOK_GLOB)].first
    end

    # State file.
    def state_file
      @state_file ||= rulebook.chomp('.rb') + '.state'
    end

    #
    #def default(*rulesets)
    #  ruleset :default => rulesets
    #end

    # Rulesets provide a separate space for rules which are only
    # run when the ruleset name is specifically given.
    #
    # Return [Ruleset]
    def ruleset(name_and_chain, &block)
      name, chain = parse_ruleset_name(name_and_chain)
      if @rulesets.key?(name)
        ruleset = @rulesets[name]
        ruleset.update(chain, &block)
      else
        ruleset = Ruleset.new(self, name_and_chain, &block)
        @rulesets[name] = ruleset
      end
      ruleset
    end

    # Import from another file, or glob of files, relative to project root.
    #
    # TODO: Should importing be relative to the importing file?
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

    #
    def inspect
      "#<Fire::System>"
    end

    # Home directory.
    #
    # Returns [String]
    def home
      @home ||= File.expand_path('~')
    end

  private

    # Parse out a ruleset's name from it's ruleset dependencies.
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
