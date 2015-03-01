module Rulebow

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    # Initialize new instanance of Rule.
    #
    # fact   - Conditional fact. [Fact,Boolean]
    # action - Procedure to run if logic condition is met. [Proc]
    #
    def initialize(fact, options={}, &action)
      @fact   = fact
      @action = action
    end

    # Access to the rule's logic condition. [Fact]
    attr :fact

    # Access to the rule's action procedure.
    #
    # Returns [Proc]
    def to_proc
      @action
    end

    # Apply rule, running the rule's procedure if the fact is true.
    #
    # Returns nothing.
    def apply(digest)
      case fact
      when false, nil
      when true
        call()
      else
        result_set = fact.call(digest)
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
