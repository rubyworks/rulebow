module Fire
  require 'fire/match'

  # Fire's logic system is purely a *set logic*. That means an empty set, `[]`
  # is treated as `false` and a non-empty set if `true`.
  #
  # Fire handle complex logic by building-up lazy logic constructs. It's logical
  # operators are defined using single charcter symbols, e.g. `&` and `|`.
  #
  class Logic
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      set @procedure.call
    end

    # set or
    def |(other)
      Logic.new{ set(self.call) | set(other.call) }
    end

    # set and
    def &(other)
      Logic.new{ set(self.call) & set(other.call) }
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
  class FileLogic < Logic
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
