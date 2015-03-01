module Rulebow

  ##
  # Digest class is used to read and write lists of files with their
  # associated checksums. This class uses SHA1.
  #
  class Digest

    # The name of the master digest.
    DEFAULT_NAME = 'default'

    # System instance. [System]
    attr :system

    # Digest of files as they are presently on disk. [Hash]
    attr :current

    # Digest of files as saved in the digest file. [Hash]
    attr :saved

    # Initialize new instance of Digest.
    #
    # Options
    #   ignore - Instance of Ignore for filtering unwanted files. [Ignore]
    #   mark   - Name of digest to load. [String]
    #
    def initialize(system)
      @system = system
      #@name   = (options[:name] || MASTER_NAME).to_s
      #@ignore = options[:ignore]

      @filename = system.state_file

      @current = Hash.new{ |h,k| h[k.to_s] = {} }
      @saved   = Hash.new{ |h,k| h[k.to_s] = {} }

      read
      refresh
    end

    # Get current digest for a given ruleset.
    def [](ruleset)
      for_ruleset(ruleset)
    end

    # The digest file's path.
    #
    # Returns [String]
    def filename
      @filename
    end

    # Remove all digests.
    def clear_all
      FileUtils.rm(filename)
    end

    # Load digest from file system.
    #
    # Returns nothing.
    def read
      return unless File.exist?(filename)

      name = DEFAULT_NAME
      save = Hash.new{ |h,k| h[k.to_s] = {} }

      File.read(filename).lines.each do |line|
        if md = /^\[(\w+)\]$/.match(line)
          name = md[1]
        end
        if md = /^(\w+)\s+(.*?)$/.match(line)
          save[name][md[2]] = md[1]
        end
      end

      save.each do |name, digest|
        @saved[name] = digest
      end
    end

    # Refresh current digest for a given ruleset, or all rulesets if not given.
    #
    # Returns nothing.
    def refresh(ruleset=nil)
      if ruleset
        ruleset = getruleset(ruleset)
        current[ruleset.name.to_s] = ruleset.watchlist.digest
      else
        system.rulesets.each do |name, ruleset|
          refresh(ruleset)
        end
      end
    end

    # Save current digest.
    #
    # Returns nothing.
    def save(ruleset=nil)
      if ruleset
        ruleset = getruleset(ruleset)
        refresh(ruleset)
        saved[ruleset.name.to_s] = current[ruleset.name.to_s]
      else
        refresh
        saved = current
      end

      dir = File.dirname(filename)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      File.open(filename, 'w') do |f|
        f << to_s
      end
    end

    # Remove digest.
    def remove(ruleset)
      case ruleset
      when Ruleset
        current.remove(ruleset.name)
      else
        current.remove(ruleset.to_str)
      end
      save
    end

    # Produce the representation of the digest that is stored to disk.
    #
    # Returns digest file format. [String] 
    def to_s
      s = ""
      saved.each do |name, list|
        s << "[#{name}]\n"
        list.each do |path, id|
          s << "#{id} #{path}\n"
        end
        s << "\n"
      end
      s
    end

    # Compute the sha1 identifer for a file.
    #
    # file - path to a file
    #
    # Returns [String] SHA1 digest string.
    def checksum(file)
      sha = ::Digest::SHA1.new
      File.open(file, 'r') do |fh|
        fh.each_line do |l|
          sha << l
        end
      end
      sha.hexdigest
    end

    # Filter files of those to be ignored.
    #
    # ruleset - instance of {Ruleset}
    # files   - files to be filtered
    #
    # Return [Array<String>]
    def filter(ruleset, files)
      #case ruleset.ignore
      #when Watchlist
        ruleset.digest.filter(files)
      #when Array
      #  files.reject!{ |path| ignore.any?{ |ig| /^#{ig}/ =~ path } }
      #else
      #  files
      #end
    end

    #
    def for_ruleset(ruleset)
      For.instance(self, getruleset(ruleset))
    end

  private

    #
    def getruleset(ruleset)
      case ruleset
      when Ruleset
        ruleset
      else
        system.rulesets[ruleset.to_sym]
      end
    end

    ##
    #
    class For

      #
      def self.instance(digest, ruleset)
        @instance ||= {}
        @instance[[digest, ruleset]] ||= new(digest, ruleset)
      end

      def initialize(digest, ruleset)
        @digest  = digest
        @ruleset = ruleset
      end

      attr :digest

      attr :ruleset

      def name
        ruleset.name.to_s
      end

      def current
        digest.current[name]
      end

      def saved
        digest.saved[name]
      end

      # Filter files.
      #
      # Return [Array<String>]
      def filter(files)
        ruleset.watchlist.filter(files)
        #case ruleset.ignore
        #when Ignore
        #  ruleset.ignore.filter(list)
        #when Array
        #  list.reject!{ |path| ignore.any?{ |ig| /^#{ig}/ =~ path } }
        #else
        #  list
        #end
      end

    end

  end

end
