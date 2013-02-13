module Fire

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

      @scripts = []
      @rules   = []
      @states  = {}
      @books   = {}

      @digest  = options[:digest] || Digest.new
      @session = OpenStruct.new

      import script if script
    end

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
 
  end

end
