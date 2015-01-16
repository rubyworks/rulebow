module Ergo

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    # Initialize new instanance of Rule.
    #
    # state  - State condition. [State,Boolean]
    # action - Procedure to run if logic condition is met. [Proc]
    #
    def initialize(state, options={}, &action)
      @state  = state
      @action = action
    end

    # Access to the rule's logic condition.
    #
    # Returns [State]
    attr :state

    # Access to the rule's action procedure.
    #
    # Returns [Proc]
    def to_proc
      @action
    end

    # Apply rule, running the rule's procedure if the state
    # condition is satisfied.
    #
    # Returns nothing.
    def apply(digest)
      case state
      when false, nil
      when true
        call()
      else
        result_set = state.call(digest)
        if result_set && !result_set.empty?
          call(result_set)
        end
      end
    end

    # Alias for #apply.
    alias :invoke :apply

  protected

    # Run rule procedure.
    #
    # result_set - The result set returned by the logic condition.
    #
    # Returns whatever the procedure returns. [Object]
    def call(*result_set)
      if @action.arity == 0
        @action.call
      else
        #@action.call(session, *result_set)
        @action.call(*result_set)
      end
    end

  end

end
