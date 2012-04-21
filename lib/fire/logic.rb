module Fire

  # TODO: Should we create our own conditional that evaluates empty as false?
  #       Would this allow Logic and SetLogic to be combined?

  # Because Fire builds-up lazy logic constructs, logical operators are
  # defined using single charcter symbols, rather than Ruby's built-in
  # double character forms, as these are not overridable. In other words
  # Fire logic statements look like:
  #
  #   a | b
  #
  # instead of 
  #
  #   a || b
  #
  class Logic
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      @procedure.call
    end

    # or
    def |(other)
      Logic.new{ self.call || other.call }
    end

    # and
    def &(other)
      Logic.new{ self.call && other.call }
    end
  end

  #
  class SetLogic
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      @procedure.call
    end

    # set or
    def |(other)
      SetLogic.new{ self.call | other.call }
    end

    # set and
    def &(other)
      SetLogic.new{ self.call & other.call }
    end
  end

  # TODO: Separate file logic?
  #class FileLogic
  #end

end
