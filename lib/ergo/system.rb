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

      @scripts = []
      @rules   = []
      @states  = {}
      @books   = {}
      @digests = {}

      import script if script
    end

    # Map of books by name.
    #
    # Returns [Hash]
    attr :books

    # Books are stored with rules to preserve order of application.
    #
    # Return [Book]
    def book(name, &block)
      @books[name.to_s] ||= (
        book = Book.new(self, name, &block)
        @rules << book
        book
      )
    end
 
    #
    def digest(name=nil)
      @digests[name] ||= Digest.new(:ignore=>ignore, :name=>name)
    end

    def digests
      @digests
    end

  end

end
