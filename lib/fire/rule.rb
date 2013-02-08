module Fire

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    # Initialize new instanance of Rule.
    #
    # logic     - Logic condition. [Logic]
    # procedure - Procedure to run if logic condition is met. [Proc]
    #
    # Options
    #   :todo   - Names of prerequisite tasks. [Array<Symbol>]
    #
    def initialize(logic, options={}, &procedure)
      @logic     = logic
      @requisite = options[:todo]
      @procedure = procedure
    end

    # Access logic condition.
    #
    # Returns [Logic]
    attr :logic

    # Returns [Proc]
    attr :procedure

    # Names of requisite tasks.
    def requisite
      @requisite
    end

    # More convenient alias for `#requisite`.
    alias :todo :requisite

    # Rules don't generally have names, but task rules do.
    def name
      nil
    end

    # Apply logic, running the rule's prcedure if the logic
    # condition is satisfied.
    #
    # Returns nothing.
    def apply(&prepare)
      case logic
      when true
        call
      when false, nil
      else
        result_set = logic.call
        if result_set && !result_set.empty?
          prepare.call
          call(*result_set)
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
      if @procedure.arity == 0
        @procedure.call
      else
        #@procedure.call(session, *args)
        @procedure.call(*result_set)
      end
    end

=begin
  private

    # Reduce todo list to the set of tasks to be run.
    #
    # Returns [Array<Task>]
    def reduce
      return [] if @_reducing
      list = []
      begin
        @_reducing = true
        @requisite.each do |r|
          next if @system.post.include?(r.to_sym)
          list << @system.tasks[r.to_sym].reduce
        end
        list << self
      ensure
        @_reducing = false
      end
      list.flatten.uniq
    end
=end

  end

end
