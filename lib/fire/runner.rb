module Fire

  # Time to DCI this shit!

  # Runner class takes a rule system and runs it.
  #
  class Runner

    def initialize(system)
      @system = system
    end

    #
    attr :system

    #
    def run_rules
      system.rules.each do |rule|
        next if rule.private?
        rule.apply
      end
    end

    #
    def run_book(name)
      system.rules.each do |rule|
        next unless rule.book?(name)
        rule.apply
      end
    end

  end

end
