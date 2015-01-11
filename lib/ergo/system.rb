module Ergo

  # Master system instance.
  #
  # Returns [System]
  #def self.system
  #  @system ||= System.new
  #end

  ##
  # A system stores defined states and rules and books, which are subsystems.
  #
  class System < Book

    # Initialize new System instance.
    #
    def initialize(script=nil, options={})
      extend self
      extend ShellUtils

      @ignore  = options[:ignore] || Ignore.new
      @session = OpenStruct.new

      @scripts  = []
      @rules    = []
      @states   = {}

      @digests  = {}
      @books    = {}
      @commands = {}

      import script if script
    end

    # Digeests [Hash]
    attr :digests

    # Books indexed by name. [Hash]
    attr :books

    # Commands indexed by name. [Hash]
    attr :commands

    #
    def default(*books)
      command :default => books
    end

    # Define a command.
    #
    def command(name_to_books)
      name_to_books.each do |name, books|
        @commands[name.to_sym] = [books].flatten.map(&:to_sym)
      end
    end

    # Books are provide a separate space for rules which are only
    # run when the book name is specifically given.
    #
    # Return [Book]
    def book(name, &block)
      name, deps = parse_name(name)
      if @books.key?(name)
        book = @books[name]
        book.update(deps, &block)
      else
        book = Book.new(self, name, &block)
        @books[name] = book
      end
      book
    end

  end

end
