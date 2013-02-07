module Fire

  # State class encapsulates a *state* definition.
  #
  class State
    # Initialize new State instance.
    #
    # name      - State's name. [Symbol]
    # condition - State's condition. [Proc]
    #
    def initialize(name, &condition)
      @name      = name
      @condition = condition
    end

    # State's name. [Symbol]
    attr :name

    # State's condition. [Proc]
    attr :condition

    # Call condition procedure.
    #
    # Returns [Boolean]
    def call(*args)
      @condition.call(*args)
    end
  end

end
