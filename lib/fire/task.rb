module Fire

  # The Task class encapsulates command-line dependent rules.
  #
  class Task
    #
    def initialize(name, options={}, &procedure)
      @name        = name
      @description = options[:desc]
      @requisite   = options[:todo] || []
      @procedure   = procedure

      #@_reducing = nil
    end

    # The tasks name.
    attr :name

    # Task description. This is need for a task to
    # available via the command line.
    attr :description

    #
    attr :requisite

    #
    alias :todo :requisite

    # Run the task.
    def invoke(&prepare)
      prepare.call
      call
    end

    # Alias for #invoke.
    alias :apply :invoke

    #def to_s
    #  @description.to_s
    #end

  protected

    #
    def call
      @procedure.call
    end

=begin
    # Reduce task list.
    #
    # Returns [Array<Task>]
    def reduce
      return [] if @_reducing
      list = []
      begin
        @_reducing = true
        @requisite.each do |r|
          list << @system.tasks[r.to_sym].reduce
        end
        list << self
      ensure
        @_reducing = false
      end
      list.flatten.uniq
    end
=end

  end

end
