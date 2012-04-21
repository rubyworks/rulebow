module Fire

  # The Task class encapsulates command-line dependent rules.
  #
  class Task
    #
    def initialize(name, system, options={}, &procedure)
      @system      = system
      @name        = name
      @description = options[:desc]
      @pre         = options[:pre] || []
      @procedure   = procedure

      @_reducing   = nil
    end

    #
    attr :description

    #
    def to_proc
      lambda{ invoke }
    end

    #
    def invoke
      reduce.each do |t|
        t.call
      end
      #call 
    end

    #
    def call
      @procedure.call
    end

    #def to_s
    #  @description.to_s
    #end

  protected

    # Reduce task list.
    #
    def reduce
      return [] if @_reducing

      list = []

      begin
        @_reducing = true

        @pre.each do |r|
          case r
          #when Logic

          when Symbol, String
            list << @system.tasks[r.to_sym].reduce
          end
        end

        list << self
      ensure
        @_reducing = false
      end

      list = list.flatten.uniq

      return list
    end

  end

end
