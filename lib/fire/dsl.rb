module Fire

  #
  module DSL

    def state(name, &condition)
      Fire.system.state(name, &condition)
    end

    def rule(logic, &procedure)
      Fire.system.rule(logic, &procedure)
    end

    def file(pattern, &procedure)
      Fire.system.file(pattern, &procedure)
    end

    def trip(state)
      Fire.system.trip(state)
    end

    def desc(description)
      Fire.system.desc(description)
    end

    def task(name_and_logic, &procedure)
      Fire.system.task(name_and_logic, &procedure)
    end

  end

end
