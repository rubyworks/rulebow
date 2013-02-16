module Osu

  ##
  # Digest class is used to read and write lists of files with their
  # associated checksums. This class uses SHA1.
  #
  class Digest

    # The name of the master digest.
    MASTER_NAME = 'MAIN'

    # The digest file to use if the root directory has a `log/` directory.
    DIRECTORY = ".osu/digest"

    # Get the name of the most recent digest given a selection of names
    # from which to choose.
    #
    # names - Selection of names. [Array<String>]
    #
    # Returns the digests name. [String]
    def self.latest(*names)
      names = names.select do |name|
        File.exist?(File.join(DIRECTORY, "#{name}.digest"))
      end
      names.max do |name|
         File.mtime(File.join(DIRECTORY, "#{name}.digest"))
      end
    end

    # Instance of Ignore is used to filter "boring files". 
    #
    # Returns [Ignore]
    attr :ignore

    # Name of digest, which corresponds to the rule bookmark.
    #
    # Returns [Ignore]
    attr :name

    # Set of files as they appear on disk.
    attr :current

    # Set of files as saved in the digest.
    attr :saved

    # Initialize new instance of Digest.
    #
    # Options
    #   ignore - Instance of Ignore for filtering unwanted files. [Ignore]
    #   mark   - Name of digest to load. [String]
    #
    def initialize(options={})
      @ignore = options[:ignore]
      @name   = options[:name] || MASTER_NAME

      @current = {}
      @saved   = {}

      read
      refresh
    end

    # The digest file's path.
    #
    # Returns [String]
    def filename
      File.join(DIRECTORY, "#{name}.digest")
    end

    # Load digest from file system.
    #
    # Returns nothing.
    def read
      file = filename
      # if the digest doesn't exist fallback to master digest
      unless File.exist?(file)
        file = File.join(DIRECTORY, "#{MASTER_NAME}.digest")
      end
      return unless File.exist?(file)

      File.read(file).lines.each do |line|
        if md = /^(\w+)\s+(.*?)$/.match(line)
          @saved[md[2]] = md[1]
        end
      end
    end

=begin
    # Gather current digest for all files.
    #
    # Returns nothing.
    def refresh
      Dir['**/*'].each do |path|
        if File.directory?(path)
          # how to handle directories as a whole?
        elsif File.exist?(path)
          id = checksum(path)
          @current[path] = id
        end
      end
    end
=end

    # Gather current digest for all files.
    #
    # Returns nothing.
    def refresh
      list = Dir['**/*']
      list = filter(list)
      list.each do |path|
        if File.directory?(path)
          # how to handle directories as a whole?
        elsif File.exist?(path)
          id = checksum(path)
          @current[path] = id
        end
      end
    end

    # Save current digest.
    #
    # Returns nothing.
    def save
      FileUtils.mkdir_p(DIRECTORY) unless File.directory?(DIRECTORY)
      File.open(filename, 'w') do |f|
        f << to_s
      end
    end

    # Remove digest.
    def remove
      if File.exist?(filename)
        FileUtils.rm(filename)
      end
    end

    # Produce the test representation of the digest that is stored to disk.
    #
    # Returns digest file format. [String] 
    def to_s
      s = ""
      current.each do |path, id|
        s << "#{id} #{path}\n"
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
    # Return [Array<String>]
    def filter(list)
      case ignore
      when Ignore
        ignore.filter(list)
      when Array
        list.reject{ |path| ignore.any?{ |ig| /^#{ig}/ =~ path } }
      else
        list
      end
    end

  end

end
