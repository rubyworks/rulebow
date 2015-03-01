module Rulebow

  ##
  # Encapsulates list of file globs to be watched.
  # 
  class WatchList

    #include Enumerable

    # Initialize new instance of Ignore.
    #
    # Returns nothing.
    def initialize(options={})
      @accept = options[:accept].to_a.flatten
      @ignore = options[:ignore].to_a.flatten
    end

    # Project's root directory.
    attr :root

    # Filter a list of files in accordance with the 
    # accept and ignore lists.
    #
    def filter(files)
      filter_ignore(filter_accept(files))
    end

    # Filter a list of files in accordance with the 
    # ignore list.
    #
    # files - The list of files. [Array<String>]
    #
    # Returns [Array<String>]
    def filter_accept(files)
      list = []
      files.each do |file|
        hit = @accept.any? do |pattern|
          match?(pattern, file)
        end
        list << file if hit
      end
      list
    end

    # Filter a list of files in accordance with the 
    # ignore list.
    #
    # files - The list of files. [Array<String>]
    #
    # Returns [Array<String>]
    def filter_ignore(files)
      list = []
      files.each do |file|
        hit = @ignore.any? do |pattern|
          match?(pattern, file)
        end
        list << file unless hit
      end
      list
    end

    #
    #def each
    #  to_a.each{ |g| yield g }
    #end

    #
    #def size
    #  to_a.size
    #end

    #
    #def to_a
    #  @list
    #end

    #
    def accept(*globs)
      @accept.concat(globs.flatten)
    end

    #
    def accept!(*globs)
      @accept.replace(globs.flatten)
    end

    #
    def ignore(*globs)
      @ignore.concat(globs.flatten)
    end

    #
    def ignore!(*globs)
      @ignore.replace(globs.flatten)
    end

    # Get a current digest.
    #
    # Returns digest. [Hash]
    def digest(root=nil)
      if root
        Dir.chdir(root) do
          read_digest
        end
      else
        read_digest
      end
    end

  private

    def read_digest
      dig = {}
      list = filter(Dir.glob('**/*', File::FNM_PATHNAME))
      list.each do |path|
        if File.directory?(path)
          # TODO: how to handle directories as a whole?
        elsif File.exist?(path)
          dig[path] = checksum(path)
        end
      end
      dig
    end

    # Given a pattern and a file, does the file match the
    # pattern? This code is based on the rules used by
    # git's .gitignore file.
    #
    # TODO: The code is probably not quite right.
    #
    # TODO: Handle regular expressions.
    #
    # Returns [Boolean]
    def match?(pattern, file)
      if Regexp === pattern
        return pattern.match(file) ? true : false
      end

      if pattern.start_with?('!')
        return !match?(pattern.sub('!','').strip)
      end

      dir = pattern.end_with?('/')
      pattern = pattern.chomp('/') if dir

      if pattern.start_with?('/')
        fnmatch?(pattern.sub('/',''), file)
      else
        if dir
          fnmatch?(File.join(pattern, '**', '*'), file) ||
          fnmatch?(pattern, file) && File.directory?(file)
        elsif pattern.include?('/')
          fnmatch?(pattern, file)
        else
          fnmatch?(File.join('**',pattern), file)
        end
      end
    end

    # Shortcut to `File.fnmatch?` method.
    #
    # Returns [Boolean]
    def fnmatch?(pattern, file, mode=File::FNM_PATHNAME)
      File.fnmatch?(pattern, file, File::FNM_PATHNAME)
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

=begin
    # Load ignore file. Removes blank lines and line starting with `#`.
    #
    # Returns [Array<String>]
    def load_ignore
      f = file
      i = []
      if f && File.exist?(f)
        File.read(f).lines.each do |line|
          glob = line.strip
          next if glob.empty?
          next if glob.start_with?('#')
          i << glob
        end
      end
      i
    end
=end

  end

end
