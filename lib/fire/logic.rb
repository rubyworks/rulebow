module Fire
  require 'fire/match'

  # TODO: Should we create our own conditional that evaluates empty as false?
  #       Would this allow Logic and SetLogic to be combined?

  # Because Fire builds-up lazy logic constructs, logical operators are
  # defined using single charcter symbols, rather than Ruby's built-in
  # double character forms, as these are not overridable. In other words
  # Fire logic statements look like:
  #
  #   a | b
  #
  # instead of 
  #
  #   a || b
  #
  class Logic
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      @procedure.call
    end

    # or
    def |(other)
      Logic.new{ self.call || other.call }
    end

    # and
    def &(other)
      Logic.new{ self.call && other.call }
    end
  end

  # Set logic.
  #
  class SetLogic
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      set @procedure.call
    end

    # set or
    def |(other)
      SetLogic.new{ set(self.call) | set(other.call) }
    end

    # set and
    def &(other)
      SetLogic.new{ set(self.call) & set(other.call) }
    end

  private

    #
    def set(value)
      if Array === value
        value.compact
      else
        value ? [value] : []
      end
    end
  end

  # File logic.
  #
  class FileLogic < SetLogic
    # Initialize new instance of Autologic.
    #
    # pattern - File glob or regular expression. [String,Regexp]
    # digest  - 
    # ignore  -
    #
    def initialize(pattern, digest, ignore)
      @pattern = pattern
      @digest  = digest
      @ignore  = ignore
    end

    # File glob or regular expression.
    attr :pattern

    # TODO: it would be nice if we could pass the regexp match too the procedure too

    # Process logic.
    def call
      result = []
      case pattern
      when Regexp
        @digest.current.keys.each do |fname|
          if md = pattern.match(fname)
            if @digest.current[fname] != @digest.saved[fname]
              result << Match.new(fname, md)
            end
          end
        end
      else
        # TODO: if fnmatch? worked like glob then we'd follow the same code as for regexp
        list = Dir[pattern].reject{ |path| @ignore.any?{ |ig| /^#{ig}/ =~ path } }
        list.each do |fname|
          if @digest.current[fname] != @digest.saved[fname]
            result << fname
          end
        end
      end
      result
    end

  end

end
