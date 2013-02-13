module Fire

  # Default rules file.
  RULES_SCRIPT = "rules{.rb,}"

  # Session is the main class which controls execution.
  #
  class Session

    # Initialize new Session instance.
    #
    # Returns nothing.
    def initialize(options={})
      @script = options[:script] || RULES_SCRIPT

      self.root   = options[:root]
      self.trial  = options[:trial]
      self.fresh  = options[:fresh]   # TODO: better name?
      self.ignore = options[:ignore]
      self.watch  = options[:watch]
  
      #load_system
    end

    # Watch period, default is every 5 minutes.
    #
    # Returns [Fixnum]
    def watch
      @watch || 300
    end

    # Set watch seconds. Minimum watch time is 1 second.
    # Setting watch before calling #run creates a simple loop.
    # It can eat up CPU cycles so use it wisely. A watch time
    # of 4 seconds is a good time period. If you are patient
    # go for 15 seconds or more.
    #
    # Returns [Fixnum,nil]
    def watch=(seconds)
      if seconds
        seconds = seconds.to_i
        seconds = 1 if seconds < 1
        @watch = seconds
      else
        @watch = nil 
      end
    end

    # Nullify digest and make a fresh run?
    #
    # Returns [Boolean]
    def fresh?
      @fresh
    end

    # Set whether to nullify digest and make a fresh run.
    #
    # Returns [Boolean]
    def fresh=(boolean)
      @fresh = !! boolean
    end

    # Is this trial-run only?
    #
    # Returns [Boolean]
    def trial?
      @trial
    end

    # Set trial run mode.
    #
    # Arguments
    #   bool - Flag for trial mode. [Boolean]
    #
    # Returns `bool` flag. [Boolean]
    def trial=(bool)
      @trial = !!bool
    end

    # Instance of {Fire::System}.
    #
    # Returns [System]
    def system
      #@system ||= Fire.system
      @system ||= System.new(*script, :digest=>digest)
    end

    # Rules script to load.
    #
    # Returns List of file paths. [Array]
    def script
      @script
    end

    # File globs to ignore.
    #
    # Returns [Ignore] instance.
    def digest
      @digest ||= Digest.new(:ignore=>ignore)
    end

    # File globs to ignore.
    #
    # Returns [Ignore] instance.
    def ignore
      @ignore ||= Ignore.new(:root=>root)
    end

    # Set ignore.
    def ignore=(file)
      @ignore = Ignore.new(:root=>root, :file=>file)
    end

    # Run rules once.
    #
    # Returns nothing.
    def run(argv)
      Dir.chdir(root) do
        if argv.size > 0
          run_book(*argv)
        else
          run_rules
        end
      end
    end

    # Run periodically.
    #
    # Returns nothing.
    def autorun(argv)
      Dir.chdir(root) do
        trap("INT") { puts "\nPutting out the fire!"; exit }
        puts "Fire started! (pid #{Process.pid})"
        loop do
          run_rules
          sleep(watch)
        end
      end
    end

    # Locate project root. This method ascends up the file system starting
    # as the current working directory looking for the rule script. When
    # a match is found, the directory in which it is found is returned as
    # the root. It is also memoized, so repeated calls to this method will
    # not repeat the search.
    #
    # Returns [String]
    def root
      @root ||= (
        r = nil
        d = Dir.pwd
        while d != home && d != '/'
          if Dir.glob(File.join(d, self.script), File::FNM_CASEFOLD).first
            break r = d
          end
          d = File.dirname(d)
        end
        abort "Can't locate project root." unless r
        r
      )
    end

    # Set the root directory.
    #
    # Returns [String]
    def root=(dir)
      @root = dir if dir
    end

    # Home directory.
    #
    # Returns [String]
    def home
      @home ||= File.expand_path('~')
    end

    # List of rules from the system.
    #
    # Returns [Array<Rule>]
    def rules
      system.rules
    end

  private

    # Returns nothing.
    #def load_system
    #  #system.ignore(*ignore)
    #  system.import(*script)
    #end

    # Run the rules.
    #
    # Returns nothing.
    def run_rules
      runner.run_rules
      save_digest
    end

    # Run the rules of a particular rule book.
    #
    # Returns nothing.
    def run_book(*args)
      runner.run_book(*args)
      save_digest
    end

    #
    #def save_pid
    #  File.open('.fire/pid', 'w') do |f|
    #    f << Process.pid.to_s
    #  end
    #end

    # Save file digest.
    #
    # Returns nothing.
    def save_digest
      digest.save
    end

    # System runner.
    #
    # Returns [Runner]
    def runner
      Runner.new(system)
    end

    # TODO: load configuration
    #
    #def rc?
    #  Dir.glob('{.c,c,C}onfig{.rb,}').first
    #end

    # Oh why is this still around? It's the original routine
    # for running rules. It worked ass backward too. Checking
    # states and then applying rules that were attached to those
    # states.
    #
    #def run
    #  @states.each do |state|
    #    session = OpenStruct.new
    #    next unless state.active?(info)
    #    @rules.each do |rule|
    #      if md = rule.match?(state)
    #        if rule.arity == 0 or md == true
    #          rule.call(info)
    #        else
    #          rule.call(info,*md[1..-1])
    #        end
    #      end
    #    end
    #  end
    #end

    # TODO: support rc profiles
    #if config = Fire.rc_config
    #  config.each do |c|
    #    if c.arity == 0
    #      system.instance_eval(&c)
    #    else
    #      c.call(system)
    #    end
    #  end
    #end

  end

end
