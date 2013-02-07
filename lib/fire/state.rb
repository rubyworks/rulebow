module Fire

  # State class encapsulates a *state* definition.
  #
  class State
    attr :name
    attr :condition

    def initialize(name, &condition)
      @name      = name
      @condition = condition
    end

    def call(*args)
      @condition.call(*args)
    end
  end

end
