require 'ostruct'

module Reap

  #
  class Reapfile

    #
    def initialize(system, file)
      @system = system
      @file   = file

      instance_eval(File.read(@file))
    end

    #
    def State(description, &condition)
      @system.state(description, &condition)
    end

    #
    def When(trigger, &procedure)
      @system.rule(trigger, &procedure)
    end

  end

  #
  class State
    attr :description
    attr :condition

    def initialize(description, &condition)
      @description = description
      @condition   = condition
    end

    def active?(info)
      @condition.call(info)
    end 
  end

  #
  class Rule
    attr :trigger
    attr :procedure

    def initialize(trigger, &procedure)
      @trigger   = trigger
      @procedure = procedure
    end

    #
    def match?(state)
      case trigger
      when Regexp
        trigger.match(state.description)
      else
        trigger == state.description
      end
    end

    #
    def call(info, *args)
      if @procedure.arity == args.size
        @procedure.call(*args)
      else
        @procedure.call(info, *args)
      end
    end

    #
    def arity
      @procedure.arity
    end

  end

end

