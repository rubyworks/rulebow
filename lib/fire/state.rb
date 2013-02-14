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

    def call(digest)
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

  ##
  # This subclass of State is specialized for file change conditions.
  #
  class FileState < State
    # Initialize new instance of FileState.
    #
    # pattern - File glob or regular expression. [String,Regexp]
    # digest  - The system digest. [Digest]
    #
    def initialize(pattern) #, digest)
      @pattern = pattern
      #@digest  = digest
    end

    # File glob or regular expression.
    attr :pattern

    # The system digest. [Digest]
    attr :digest

    # Process logic.
    def call(digest)
      result = []
      case pattern
      when Regexp
        list = Dir.glob('**/*', File::FNM_PATHNAME)
        list = digest.filter(list)
        list.each do |fname|
          if md = pattern.match(fname)
            if digest.current[fname] != digest.saved[fname]
              result << Match.new(fname, md)
            end
          end
        end
        # NOTE: The problem with using the digest list, is that if a rule
        #       adds a new file to the project, then a subsequent rule needs
        #       to be able to see it.
        #@digest.current.keys.each do |fname|
        #  if md = pattern.match(fname)
        #    if @digest.current[fname] != @digest.saved[fname]
        #      result << Match.new(fname, md)
        #    end
        #  end
        #end
      else
        list = Dir.glob(pattern, File::FNM_PATHNAME)
        list = digest.filter(list)
        list.each do |fname|
          if digest.current[fname] != digest.saved[fname]
            result << fname
          end
        end
        #@digest.current.keys.each do |fname|
        #  if md = File.fnmatch?(pattern, fname, File::FNM_PATHNAME | File::FNM_EXTGLOB)
        #    if @digest.current[fname] != @digest.saved[fname]
        #      result << Match.new(fname, md)
        #    end
        #  end
        #end
      end
      result
    end

  end

end
