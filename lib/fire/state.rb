module Fire

  ##
  # Fire's logic system is a *set logic* system. That means an empty set, `[]`
  # is treated as `false` and a non-empty set is `true`.
  #
  # Fire handles complex logic by building-up lazy logic constructs. It's logical
  # operators are defined using single charcter symbols, e.g. `&` and `|`.
  #
  class State
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      set @procedure.call
    end

    # set or
    def |(other)
      State.new{ set(self.call) | set(other.call) }
    end

    # set and
    def &(other)
      State.new{ set(self.call) & set(other.call) }
    end

  private

    #
    def set(value)
      case value
      when Array
        value.compact
      when Boolean
        value ? true : []
      else
        [value]
      end
    end

  end

  # File state.
  #
  class FileState < State
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
