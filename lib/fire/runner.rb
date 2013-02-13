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
        case rule
        when Book
          rule.rules.each do |rule|
            rule.apply unless rule.private?
          end
        else
          rule.apply unless rule.private?
        end
      end
    end

    #
    def run_mark(name)
      if book = system.books[name.to_sym]
        book.rules.each do |rule|
          next unless rule.mark?(name)
          rule.apply
        end
      end

      system.rules.each do |rule|
        case rule
        when Book
          rule.rules.each do |rule|
            next unless rule.mark?(name)
            rule.apply
          end
        else
          next unless rule.mark?(name)
          rule.apply
        end
      end
    end

  end

end
