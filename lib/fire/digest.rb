module Fire

  ##
  # Digest class is used to read and write lists of files with their
  # associated checksums. This class uses SHA1.
  #
  class Digest

    # The digest file to use if the root directory has a `log/` directory.
    LOGFILE = "log/fire.digest"

    # The digest file to use if the root directory does not have a `log/` directory.
    DOTFILE = ".digest"

    # Set of files as they appear on disk.
    attr :current

    # Set of files as saved in the digest.
    attr :saved

    # Instance of Ignore is used to filter "boring files". 
    #
    # Returns [Ignore]
    attr :ignore

    # Initialize new instance of Digest.
    #
    # Options
    #   file   - Digest file path relative to the rule script. [String]
    #   ignore - Instance of Ignore for filtering unwanted files. [Ignore]
    #
    def initialize(options={})
      @file   = options[:file]
      @ignore = options[:ignore]

      @current = {}
      @saved   = {}

      read
      refresh
    end

    # Digest file, path is relative to the rules script.
    #
    # Returns file name. [String]
    def file
      @file ||= (
        if File.directory?('log')
          LOGFILE
        else
          DOTFILE
        end
      )
    end

    # Load saved digest.
    #
    # Returns nothing.
    def read
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
      dir = File.dirname(file)
      FileUtils.mkdir(dir) unless File.directory?(dir)
      File.open(file, 'w'){ |f| f << to_s }      
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
