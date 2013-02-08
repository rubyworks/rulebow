module Fire

  # Time to DCI this shit!

  # Runner class takes a rule system and runs it.
  #
  class Runner

    def initialize(system)
      @system = system
      @_post = []
    end

    #
    attr :system

    #
    def run_rules
      system.rules.each do |rule|
        rule.apply{ prepare(rule) }
      end
    end

    #
    def run_task(trigger)
      task = system.tasks[trigger.to_sym]
      task.apply{ prepare(task) }
    end

  private

    # Execute rule by first running any outstanding prerequistes
    # then then the rul procedure itself.
    def prepare(rule)
      pre = resolve(rule)
      pre = pre - post
      pre = pre - [rule.name.to_sym] if rule.name
      pre.each do |r|
        r.call
      end
      post(pre)
    end

    # TODO: It would be nice #resolve could detect infinite recursions
    #       and raise an error.
    #

    # Resolve prerequistes.
    #
    # Returns [Array<Symbol>]
    def resolve(rule, todo=[])
      return [] if (rule.todo - todo).empty?
      left = rule.todo - todo
      list = left
      todo.concat(left)
      left.each do |r|
        t = system.tasks[r.to_sym]
        x = resolve(t, todo)
        list.concat(x)
      end
      list.uniq 
    end

    # List of prerequistes that have already been run.
    # Keeping this list prevents the same prequistes
    # from ever being run twice in the same session.
    #
    # Returns [Array<Symbol>]
    def post(pre=nil)
      @_post.concat(pre) if pre
      @_post
    end

  end

end
