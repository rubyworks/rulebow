module Fire

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    # Initialize new instanance of Rule.
    #
    # state     - State condition. [Logic]
    # procedure - Procedure to run if logic condition is met. [Proc]
    #
    # Options
    #   desc - Description of rule. [Array<Symbol>]
    #
    def initialize(state, options={}, &procedure)
      self.state   = state
      self.desc    = options[:desc]
      self.book    = options[:book]
      self.private = options[:private]

      @proc  = procedure
    end

    # Access logic condition.
    #
    # Returns [State]
    attr :state

    # Description of rule.
    #
    # Returns [String]
    def description
      @desc
    end

    #
    alias :to_s :description

    # Books to which this rule belongs.
    #
    # Returns [Array<String>]
    attr :book

    #
    def book?(name)
      @book.include?(name.to_s)
    end
 
    # Is the rule private? A private rule does not run with the "master book",
    # only when it's specific book is invoked.
    def private?
      @private
    end

    # Rule procedure.
    #
    # Returns [Proc]
    def to_proc
      @proc
    end

    # Apply rule, running the rule's procedure if the state
    # condition is satisfied.
    #
    # Returns nothing.
    def apply
      case state
      when true
        call
      when false, nil
      else
        result_set = state.call
        if result_set && !result_set.empty?
          call(*result_set)
        end
      end
    end

    # Alias for #apply.
    alias :invoke :apply

  protected

    # Set state of rule.
    def state=(state)
      #raise unless State === state || Boolean === state
      @state = state
    end

    # Set book(s) of rule.
    def book=(names)
      @book = Array(names).map{ |b| b.to_s }
    end

    # Set privacy of rule. A private rule does not run with the "master book",
    # only when it's specific book is invoked.
    def private=(boolean)
      @private = !! boolean
    end

    # Set description of rule.
    def desc=(string)
      @desc = string.to_s
    end

    # Run rule procedure.
    #
    # result_set - The result set returned by the logic condition.
    #
    # Returns whatever the procedure returns. [Object]
    def call(*result_set)
      if @proc.arity == 0
        @proc.call
      else
        #@procedure.call(session, *args)
        @proc.call(*result_set)
      end
    end

  end

end
