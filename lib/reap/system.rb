require 'ostruct'
require 'reap/reapfile'
require 'reap/digest'

module Reap

  module ShellUtils
    def sh(*args)
      puts args.join(' ')
      system(*args)
    end
  end

  # System stores states and rules.
  class System < Module

    # Instantiate new system.
    #
    def initialize(ignore, *files)
      extend self

      extend ShellUtils

      @ignore  = ignore || []
      @states  = []
      @rules   = []
      @files   = files
      @tasks   = {}

      @digest  = Digest.new

      @session = OpenStruct.new

      files.each do |file|
        instance_eval(File.read(file), file)
      end
    end

    # Current session.
    attr :session

    # Array of defined states.
    attr :states

    # Array of defined rules.
    attr :rules

    # Mapping of defined tasks.
    attr :tasks

    # File digest.
    attr :digest

    # Set paths to be ignored in file rules.
    def ignore(*globs)
      @ignore.concat(globs.flatten)
      @ignore
    end

    # Define a named state. States define logic methods that 
    # can be used by rules.
    #
    # @example
    #   state :no_rdocs do
    #     files = Dir.glob('lib/**/*.rb')
    #     FileUtils.uptodate?('doc', files) ? files : false
    #   end
    #
    def state(name, &condition)
      state = State.new(name, &condition)
      define_method(name) do |*args, &block|
        Logic.new{ state.call(*args, &block) }
      end
      @states << state
    end

    # Define a rule. Rules are procedures that are tiggered 
    # by logical states.
    #
    # @example
    #   rule no_rdocs do |files|
    #     sh "rdoc --output doc/rdoc " + files.join(" ")
    #   end
    #
    def rule(logic, &procedure)
      @rules << Rule.new(logic, &procedure)
    end

    # TODO: do we want to rename #file to #path so we might support
    # Rake-style file tasks in the future?

    # Define a file rule. A file rule is a rule with a specific state logic
    # based on changes in files.
    #
    # @example
    #   file 'test/**/case_*.rb' do |files|
    #     sh "ruby-test " + files.join(" ")
    #   end
    #
    def file(pattern, &procedure)
      logic = SetLogic.new do
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
      @rules << Rule.new(logic, &procedure)
    end

    #
    def trip(state)
      puts "STATE: #{state}"
    end

    # Set task description. The next task defined will get the most
    # recently defined description attached to it.
    def desc(description)
      @_desc = description
    end

    # TODO: command line interfaces
    #   Could we support tasks with specific ARGV signitures?
    #   e.g. cli(args, :opt1=>Intger, :opt2=>String, :opt3=>FalseClass)

    # Define a command line task. A task is special type of rule that
    # is triggered when the `reap` command line tool is invoked with
    # the name of the task.
    #
    # Tasks are an isolated set of rules and suppress the activation of
    # all other rules not specifically given as task pre-requisites.
    #
    #   task :rdoc do
    #     trip no_rdocs
    #   end
    #
    def task(name_and_logic, &procedure)
      case name_and_logic
      when Hash
        name, pre = *name_and_logic.to_a.first
      else
        name, pre = name_and_logic, []
      end

      task = Task.new(name, self, :pre=>pre, :desc=>@_desc, &procedure)

      #logic = Logic.new do
      #  ARGV.first == name.to_s
      #end
      #@rules << Rule.new(logic, &task)

      @tasks[name.to_sym] = task
      @_desc = nil
    end

    #def eval(script)
    #  @evaluator ||= Reapfile.new(self)
    #  @evaluator.eval(script)
    #end
  end

  # State class encapsulates a *state* definition.
  #
  class State
    attr :name
    attr :condition

    def initialize(nane, &condition)
      @name      = name
      @condition = condition
    end

    def call
      @condition.call
    end
  end

  # Rule class encapsulates a *rule* definition.
  #
  class Rule
    attr :logic
    attr :procedure

    #
    def initialize(logic, &procedure)
      @logic     = logic
      @procedure = procedure
    end

    #
    def apply
      case logic
      when true
        call
      when SetLogic
        result = logic.call
        if result && !result.empty?
          call(result)
        end
      else
        result = logic.call
        if result
          call(*result)
        end
      end
    end

    #
    #def match?(state)
    #  case trigger
    #  when Regexp
    #    trigger.match(state.description)
    #  else
    #    trigger == state.description
    #  end
    #end

    #
    #def active?
    #  case logic
    #  when true
    #    true
    #  else
    #    logic.call
    #  end
    #end

    #
    def call(*logic_result)
      if @procedure.arity == 0
        @procedure.call
      else
        #@procedure.call(session, *args)
        @procedure.call(*logic_result)
      end
    end

    # Arity of the procedure that defines the logic condition.
    def arity
      @procedure.arity
    end
  end

  # Because Reap builds-up lazy logic constructs, logical operators are
  # defined using single charcter symbols, rather than Ruby's built-in
  # double character forms, as these are not overridable. In other words
  # Reap logic statements look like:
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

  #
  class SetLogic
    def initialize(&procedure)
      @procedure = procedure
    end

    def call
      @procedure.call
    end

    # set or
    def |(other)
      Logic.new{ self.call | other.call }
    end

    # set and
    def &(other)
      Logic.new{ self.call & other.call }
    end
  end


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
