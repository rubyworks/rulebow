module Reap

  class Engine

    def initialize
      @states = {}
      @rules  = []
    end

    def state(name, &condition)
      @states[name] = State.new(name, &condition)
    end

    def rule(*triggers, &procedure)
      @rules << Rule.new(*triggers, &procedure)
    end

    def eval(script)
      @evaluator ||= Eval.new(self)
      @evaluator.eval(script)
    end

    def run
      @rules.each do |rule|
        if rule.triggers.all?{ |name| @states[name].call }
          rule.call
        end
      end
    end

  end

  #
  class Eval

    def initialize(engine)
      @engine = engine
    end

    def eval(script)
      instance_eval(script) #File.read(file))
    end

    def state(name, &condition)
      @engine.state(name, &condition)
    end

    def rule(*triggers, &procedure)
      @engine.rule(*triggers, &procedure)
    end

  end

  #
  class State
    attr :name
    attr :condition

    def initialize(name, &condition)
      @name = name
      @condition = condition
    end

    def call
      @condition.call
    end
  end

  #
  class Rule
    attr :triggers
    attr :procedure

    def initialize(*triggers, &procedure)
      @triggers  = triggers
      @procedure = procedure
    end

    def call
      @procedure.call
    end
  end

end

