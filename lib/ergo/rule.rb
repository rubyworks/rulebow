module Ergo

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    # Initialize new instanance of Rule.
    #
    # state     - State condition. [Logic]
    # procedure - Procedure to run if logic condition is met. [Proc]
    #
    # Options
    #   desc - Description of rule. [String]
    #   mark - List of bookmark names. [Array<String>]
    #
    def initialize(state, options={}, &procedure)
      self.state   = state
      self.desc    = options[:desc] || options[:description]
      self.mark    = options[:mark] || options[:bookmarks]
      self.private = options[:private]

      @proc = procedure
    end

    # Access logic condition.
    #
    # Returns [State]
    attr :state

    # Description of rule.
    #
    # Returns [String]
    def description
      @description
    end

    # Returns the description.
    #
    # Returns [String]
    alias :to_s :description

    # Rule bookmarks.
    #
    # Returns [Array<String>]
    def bookmarks
      @bookmarks
    end

    #
    def bookmark?(name)
      @bookmarks.include?(name.to_s)
    end
    alias :mark? :bookmark?

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
    def apply(digest)
      case state
      when true
        call
      when false, nil
      else
        result_set = state.call(digest)
        if result_set && !result_set.empty?
          call(result_set)
        end
      end
    end

    # Alias for #apply.
    alias :invoke :apply

    # Convenience method for producing a rule list.
    #
    # Rertuns [Array]
    def to_a
      [description, bookmarks, private?]
    end

  protected

    # Set state of rule.
    def state=(state)
      #raise unless State === state || Boolean === state
      @state = state
    end

    # Set bookmark(s) of rule.
    def mark=(names)
      @bookmarks = Array(names).map{ |b| b.to_s }
    end

    # Set privacy of rule. A private rule does not run with the "master book",
    # only when it's specific book is invoked.
    def private=(boolean)
      @private = !! boolean
    end

    # Set description of rule.
    def desc=(string)
      @description = string.to_s
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
