module Ergo

  # Master system instance.
  #
  # Returns [System]
  #def self.system
  #  @system ||= System.new
  #end

  ##
  #
  class System < Module

    # Initialize new System instance.
    #
    def initialize(options={})
      extend self
      extend ShellUtils

      @config  = options[:config]
      @root    = options[:root]   || Dir.pwd
      @ignore  = options[:ignore] || Ignore.new

      @session = OpenStruct.new

      @scripts  = []
      @rules    = []
      #@states  = []

      @digests  = {}
      @books    = {}

      import @config if @config
    end

    # Digests [Hash]
    attr :digests

    # Books indexed by name. [Hash]
    attr :books

    #
    attr :session

    #
    attr :config

    #
    #def default(*books)
    #  book :default => books
    #end

    # Define a command.
    #
    #def command(name_to_books)
    #  name_to_books.each do |name, books|
    #    @commands[name.to_sym] = [books].flatten.map(&:to_sym)
    #  end
    #end

    # Books are provide a separate space for rules which are only
    # run when the book name is specifically given.
    #
    # Return [Book]
    def book(name_and_chain, &block)
      name, chain = parse_book_name(name_and_chain)
      if @books.key?(name)
        book = @books[name]
        book.update(chain, &block)
      else
        book = Book.new(self, name_and_chain, &block)
        @books[name] = book
      end
      book
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
      "#<Ergo::System>"
    end

    # Home directory.
    #
    # Returns [String]
    def home
      @home ||= File.expand_path('~')
    end

  private

    # Parse out a book's name from it's book dependencies.
    #
    # Returns [Array]
    def parse_book_name(name)
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
