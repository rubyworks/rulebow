module Fire

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    # Initialize new instanance of Rule.
    #
    # logic     - Logic condition [Logic]
    # procedure - Procedure to run if logic condition is met.
    #
    def initialize(logic, &procedure)
      @logic     = logic
      @procedure = procedure
    end

    # Access logic condition.
    #
    # Returns [Logic]
    attr :logic

    # Returns [Proc]
    attr :procedure

    # Apply logic, running the rule's prcedure if the logic
    # condition is satisfied.
    #
    # Returns nothing.
    def apply
      case logic
      when true
        call
      else
        result_set = logic.call
        if result_set && !result_set.empty?
          call(*result_set)
        end
      end
    end

    # Query if the logic condition passes.
    #
    # Returns [Boolean]
    def applicable?
      case logic
      when true
        true
      else
        result_set = logic.call
        result_set && !result_set.empty?
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

    # Run rule procedure.
    #
    # result_set - The result set returned by the logic condition.
    #
    # Returns whatever the procedure returns. [Object]
    def call(*result_set)
      if @procedure.arity == 0
        @procedure.call
      else
        #@procedure.call(session, *args)
        @procedure.call(*result_set)
      end
    end

    # Arity of the procedure that defines the logic condition.
    #
    # Returns [Fixnum]
    def arity
      @procedure.arity
    end

    # Access to the rule procedure.
    #
    # Returns [Proc]
    def to_proc
      @procedure
    end
  end

end
