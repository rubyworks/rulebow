module Fire

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    attr :logic
    attr :procedure

    #
    def initialize(logic, &procedure)
      @logic     = logic
      @procedure = procedure
    end

    #
    def apply
      case logic
      when true
        call
      when SetLogic
        result = logic.call
        if result && !result.empty?
          call(result)
        end
      else
        result = logic.call
        if result
          call(*result)
        end
      end
    end

    #
    #def match?(state)
    #  case trigger
    #  when Regexp
    #    trigger.match(state.description)
    #  else
    #    trigger == state.description
    #  end
    #end

    #
    #def active?
    #  case logic
    #  when true
    #    true
    #  else
    #    logic.call
    #  end
    #end

    #
    def call(*logic_result)
      if @procedure.arity == 0
        @procedure.call
      else
        #@procedure.call(session, *args)
        @procedure.call(*logic_result)
      end
    end

    # Arity of the procedure that defines the logic condition.
    def arity
      @procedure.arity
    end
  end

end
