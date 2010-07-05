require 'ostruct'

module Reap

  # System stores states and rules.
  class System

    def initialize(*files)
      @states = []
      @rules  = []
      @files  = []

      files.each do |file|
        self << file
      end
    end

    def <<(file)
      @files << Reapfile.new(self, file)
    end

    def state(description, &condition)
      @states << State.new(description, &condition)
    end

    def rule(trigger, &procedure)
      @rules << Rule.new(trigger, &procedure)
    end

    #def eval(script)
    #  @evaluator ||= Reapfile.new(self)
    #  @evaluator.eval(script)
    #end

    def run
      @states.each do |state|
        info = OpenStruct.new
        next unless state.active?(info)
        @rules.each do |rule|
          if md = rule.match?(state)
            if rule.arity == 0 or md == true
              rule.call(info)
            else
              rule.call(info,*md[1..-1])
            end
          end
        end
      end
    end

  end

end

