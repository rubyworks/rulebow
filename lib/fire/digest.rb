require 'digest/sha1'
require 'fileutils'

module Fire

  #
  class Digest

    #
    DEFAULT_FILE = ".fire/digest"

    #
    attr :file

    #
    attr :current

    #
    attr :saved

    #
    attr :ignore

    #
    def initialize(options={})
      @file   = options[:file]   || DEFAULT_FILE
      @ignore = options[:ignore] || []

      @current = {}
      @saved   = {}

      read
      refresh
    end

    # Load saved digest.
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
      list = list.reject{ |path| ignore.any?{ |ig| /^#{ig}/ =~ path } }
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
    def save
      dir = File.dirname(file)
      FileUtils.mkdir(dir) unless File.directory?(dir)
      File.open(file, 'w'){ |f| f << to_s }      
    end

    # Returns [String] digest file format.
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

  end

end
