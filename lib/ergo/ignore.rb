module Ergo

  # This file can be used as an alternative to using the #ignore method 
  # to define what paths to ignore.
  IGNORE_FILE = '.ergo/ignore'

  ##
  # Encapsulates list of file globs to be ignored.
  #
  class Ignore
    include Enumerable

    # Initialize new instance of Ignore.
    #
    # Returns nothing.
    def initialize(options={})
      case options
      when Array, Ignore
        @ignore = options.to_a
      else
        @file = options[:file]
        @root = options[:root]
        @ignore = load_ignore
      end
    end

    # Filter a list of files in accordance with the 
    # ignore list.
    #
    # files - The list of files. [Array<String>]
    #
    # Returns [Array<String>]
    def filter(files)
      list = []
      files.each do |file|
        hit = any? do |pattern|
          match?(pattern, file)
        end
        list << file unless hit
      end
      list
    end

    # Returns [Array<String>]
    #def ignore
    #  @ignore ||= load_ignore
    #end

    # Ignore file.
    def file
      @file ||= (
        Dir["{.gitignore,.hgignore,#{IGNORE_FILE}}"].first
      )
    end

    #
    def each
      to_a.each{ |g| yield g }
    end

    #
    def size
      to_a.size
    end

    #
    def to_a
      @ignore #||= load_ignore
    end

    #
    def replace(*globs)
      @ignore = globs.flatten
    end

    #
    def concat(*globs)
      @ignore.concat(globs.flatten)
    end

  #private

    #def all_ignored_files
    #  list = []
    #  ignore.each do |glob|
    #    if glob.start_with?('/')
    #      list.concat Dir[File.join(@root, glob)]
    #    else
    #      list.concat Dir[File.join(@root, '**', glob)]
    #    end
    #  end
    #  list
    #end

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

    # Given a pattern and a file, does the file match the
    # pattern? This code is based on the rules used by
    # git's .gitignore file.
    #
    # TODO: The code is probably not quite right.
    #
    # Returns [Boolean]
    def match?(pattern, file)
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

  end

end
