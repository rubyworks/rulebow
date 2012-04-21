module Fire

  class FileLogic < SetLogic

    #
    def initialize(pattern, digest)
      @pattern = pattern
      @digest  = digest
    end

    #
    attr :pattern

    #
    def call
      result = []
      case pattern
      when Regexp
        digest.current.keys.each do |fname|
          if md = pattern.match(fname)
            if digest.current[fname] != digest.saved[fname]
              result << md
            end
          end
        end
      else
        # TODO: if fnmatch? worked like glob then we'd follow the same code as for regexp
        list = Dir[pattern].reject{ |path| ignore.any?{ |ig| /^#{ig}/ =~ path } }
        list.each do |fname|
          if digest.current[fname] != digest.saved[fname]
            result << fname
          end
        end
      end
      result
    end

  end

end
