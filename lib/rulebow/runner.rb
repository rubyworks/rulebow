module Rulebow

  # Runner is the main class which controls execution.
  #
  class Runner

    RULEBOOK_GLOB = "{,.,_}{R,r}ulebook{,.rb}"

    # Initialize new Runner instance.
    #
    # Returns nothing.
    def initialize(options={})
      self.ignore = options[:ignore]  # Deprecate?

      self.trial  = options[:trial]
      self.fresh  = options[:fresh]
      self.watch  = options[:watch]

      if options[:system]
        @system = options[:system]
        @root   = @system.root
      else
        locate_root
        @system = System.new(:root=>root)
      end
    end

    # Project's root directory.
    #
    # Returns [String]
    def root
      @root
    end

    # Locate project root. This method ascends up the file system starting
    # as the current working directory looking for a `Rulebook` file.
    # When found, the directory in which it is found is returned as the root.
    def locate_root
      d = Dir.pwd
      while d != home && d != '/'
        f = Dir.glob(File.join(d, RULEBOOK_GLOB)).first
        if f
          @root = d
          break
        end
        d = File.dirname(d)
      end
      raise(RootError, "cannot locate project root") unless @root
      @root
    end

    #
    #def root=(path)
    #  @root = path
    #end

    # Home directory.
    #
    # Returns [String]
    def home
      @home ||= File.expand_path('~')
    end

    # Config script.
    #def config
    #  @config ||= Dir[CONFIG_SCRIPT].first
    #end

    # Set config script.
    #def config=(script)
    #  @config = script
    #end

    # Watch period, default is every 5 minutes.
    #
    # Returns [Fixnum]
    def watch
      @watch
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
    # TODO: Trial mode is not implemented yet!
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

    # Set the root directory.
    #
    # Returns [String]
    #def root=(dir)
    #  @root = dir if dir
    #end

    # Instance of {Rulebow::System}.
    #
    # Returns [System]
    def system
      @system #||= System.new(script)
    end

    ## Rules script to load.
    ##
    ## Returns List of file paths. [Array]
    #def script
    #  @script || (@system ? nil : Dir[RULES_SCRIPT].first)
    #end

    #
    #
    #
    def rulesets
      system.rulesets
    end

    # File globs to ignore.
    #
    # Returns [Ignore] instance.
    #def digest
    #  @digest ||= Digest.new(:ignore=>ignore)
    #end

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

    # List of rules from the system.
    #
    # Returns [Array<Rule>]
    def rules
      system.rules
    end

    # Run rules.
    #
    # Returns nothing.
    def run(name)
      name = (name || :default).to_sym

      if watch
        autorun(name)
      else
        monorun(name)
      end
    end

  private

    # Run rules once.
    #
    # Returns nothing.
    def monorun(name)
      Dir.chdir(root) do
        fresh_digest(name) if fresh?
        run_ruleset(name)
      end
    end

    # Run rules periodically.
    #
    # Returns nothing.
    def autorun(name)
      Dir.chdir(root) do
        fresh_digest(name) if fresh?

        trap("INT") { puts "\nBows down."; exit }

        puts "    (        RULEBOW "
        puts "     \\       (pid #{Process.pid})"
        puts "      )      "
        puts " ##--------> "
        puts "      )      "
        puts "     /       "
        puts "    (        "

        loop do
          run_ruleset(name)
          sleep(watch)
        end
      end
    end

    # Run a specific ruleruleset.
    #
    # name - Nmae of ruleset. [String].
    #
    # Returns nothing.
    def run_ruleset(name)
      rulesets = ruleset_chain(name)
      rulesets.each do |ruleset|
        run_rules(ruleset)
        digest.save(ruleset)
      end
    end

    # Run all rulesets.
    #
    def run_all
      run_rules(system)
      digest.clear
      digest.save
    end

=begin
    # Run only those rules with a specific rulesetmark.
    #
    # marks - Bookmark names. [Array<String>].
    #
    # Returns nothing.
    def run_rulesetmarks(*marks)
      system.rules.each do |rule|
        case rule
        when Ruleset
          ruleset = rule
          ruleset.rules.each do |rule|
            next unless marks.any?{ |mark| rule.mark?(mark) }
            rule.apply(latest_digest(rule))
          end
        else
          next unless marks.any?{ |mark| rule.mark?(mark) }
          rule.apply(latest_digest(rule))
        end
      end

      save_digests(*marks)
    end
=end

    # Run set of rules.
    #
    # Returns nothing.
    def run_rules(ruleset)
      ruleset.rules.each do |rule|
        rule.apply(digest[ruleset])
      end
    end

    # Instance of Digest for this system.
    def digest
      @digest ||= Digest.new(system)
    end

    # Start with a clean slate by removing the digest.
    #
    # Returns nothing.
    def fresh_digest(name)
      if name
        chain = ruleset_chain(name)
        chain.each do |n|
          digest.remove(n)
        end
      else
        digest.clear_all
      end
    end

    # Save digests for given rulesets.
    #
    # Returns nothing.
    def save_digests(*rulesets)
      rulesets.each do |name|
        digest.save(name)
      end
    end

    # Get ruleset instance for a given command.
    def ruleset_chain(name)
      ruleset = verify_ruleset!(name)
      chain = []
      build_chain(ruleset, chain)
      chain.uniq
    end

    #
    def build_chain(ruleset, chain=[])
      ruleset.chain.each do |name|
        verify_ruleset!(name)
        build_chain(rulesets[name], chain)
      end
      chain << ruleset
      return chain
    end

    #
    def verify_ruleset!(name)
      name = name.to_sym
      unless rulesets.key?(name)
        raise(ArgumentError, "unknown ruleset name -- #{name}")
      end
      rulesets[name]
    end

=begin
    #
    def calc_chain(*marks)
      chain = []
      order = []

      marks.each do |mark|
        if mark.include?(':')
          k, p = mark.split(':')
          raise "unknown chain -- #{k}" unless system.chains.key?(k)
          order << system.chains[k][0..(system.chains[k].index(p))]
        else
          order << mark
        end
      end
      order = order.flatten.uniq

      order.each do |name|
        complete_chain(name, chain)
      end

      return chain.uniq
    end

    #
    def complete_chain(name, chain)
      if system.rulesets.key?(name)
        system.rulesets[name].chain.each do |n|
          complete_chain(n, chain)
        end
      end
      chain << name
      return chain
    end
=end

    # TODO: If we ever need this, we will need to put it in the state file.
    #def save_pid
    #  File.open('.bow/pid', 'w') do |f|
    #    f << Process.pid.to_s
    #  end
    #end

    # Save file digest.
    #
    # Returns nothing.
    #def save_digest(*marks)
    #  digest.save(*marks)
    #end

    # System runner.
    #
    # Returns [Runner]
    #def runner
    #  Runner.new(system)
    #end

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
    #if config = Rulebow.rc_config
    #  config.each do |c|
    #    if c.arity == 0
    #      system.instance_eval(&c)
    #    else
    #      c.call(system)
    #    end
    #  end
    #end

    #
    class RootError < RuntimeError
    end

  end

end
