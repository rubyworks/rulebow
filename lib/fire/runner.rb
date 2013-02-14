module Fire

  # Runner class takes a rule system and runs it.
  #
  # Note: It is interesting to note, from a developer's perspective,
  #       that this class was created via the application of certain
  #       DCI concepts. Specifically, this class is a *context*.
  #
  class Runner

    # Initialize new Runner instance.
    def initialize(system)
      @system = system
    end

    # Returns [System]
    attr :system

    # Run all rules.
    def run_rules
      system.rules.each do |rule|
        case rule
        when Book
          book = rule
          book.rules.each do |rule|
            next if rule.private?
            rule.apply(digest(rule))
          end
        else
          next if rule.private?
          rule.apply(digest(rule))
        end
      end

      clear_digests

      @system.digest.save
    end

    # Run only those rules with a specific bookmark.
    #
    # Returns nothing.
    def run_bookmarks(*marks)
      system.rules.each do |rule|
        case rule
        when Book
          book = rule
          book.rules.each do |rule|
            next unless marks.any?{ |mark| rule.mark?(mark) }
            rule.apply(digest(rule))
          end
        else
          next unless marks.any?{ |mark| rule.mark?(mark) }
          rule.apply(digest(rule))
        end
      end

      save_digests(*marks)
    end

    # Get the most recent digest for a given rule.
    #
    # Returns [Digest]
    def digest(rule)
      name = Digest.latest(*rule.bookmarks)
      @system.digest(name)
    end

    # Save digests for given bookmarks.
    #
    # Returns nothing.
    def save_digests(*bookmarks)
      bookmarks.each do |mark|
        @system.digest(mark).save
      end
    end

    # Clear away all digests but the main digest.
    #
    # Returns nothing.
    def clear_digests
      @system.digests.each do |name, digest|
        digest.remove if name
      end
    end

  end

end
