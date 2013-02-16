module Ergo

  # Default rules file.
  RULES_SCRIPT = ".ergo/script.rb"

  # Runner is the main class which controls execution.
  #
  class Runner

    # Initialize new Session instance.
    #
    # Returns nothing.
    def initialize(options={})
      @script     = options[:script]
      @system     = options[:system]

      self.root   = options[:root]
      self.trial  = options[:trial]
      self.fresh  = options[:fresh]
      self.watch  = options[:watch]
      self.ignore = options[:ignore]
  
      @digests = {}
    end

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

    # Locate project root. This method ascends up the file system starting
    # as the current working directory looking for a `.ergo` directory.
    # When found, the directory in which it is found is returned as the root.
    # It is also memoized, so repeated calls to this method will not repeat
    # the search.
    #
    # Returns [String]
    def root
      dir = root?
      raise RootError, "cannot locate project root" unless dir
      dir
    end

    #
    def root?
      @root ||= (
        r = nil
        d = Dir.pwd
        while d != home && d != '/'
          if File.directory?('.ergo')
            break r = d
          end
          d = File.dirname(d)
        end
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

    # Instance of {Ergo::System}.
    #
    # Returns [System]
    def system
      @system ||= System.new(script)
    end

    # Rules script to load.
    #
    # Returns List of file paths. [Array]
    def script
      @script || (@system ? nil : Dir[RULES_SCRIPT].first)
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
    def run(*marks)
      raise ArgumentError, "invalid bookmark" unless marks.all?{ |m| /\w+/ =~ m }

      if watch
        autorun(*marks)
      else
        monorun(*marks)
      end
    end

  private

    # Run rules once.
    #
    # Returns nothing.
    def monorun(*marks)
      Dir.chdir(root) do
        fresh_digest(*marks) if fresh?

        if marks.size > 0
          run_bookmarks(*marks)
        else
          run_rules
        end
      end
    end

    # Run rules periodically.
    #
    # Returns nothing.
    def autorun(*marks)
      Dir.chdir(root) do
        fresh_digest(*marks) if fresh?

        trap("INT") { puts "\nPutting out the fire!"; exit }
        puts "Fire started! (pid #{Process.pid})"

        if marks.size > 0
          loop do
            run_bookmarks(*marks)
            sleep(watch)
          end
        else
          loop do
            run_rules
            sleep(watch)
          end
        end
      end
    end

    # Returns [Hash]
    attr :digests

    # Run all rules (expect private rules).
    #
    # Returns nothing.
    def run_rules
      system.rules.each do |rule|
        case rule
        when Book
          book = rule
          book.rules.each do |rule|
            next if rule.private?
            rule.apply(latest_digest(rule))
          end
        else
          next if rule.private?
          rule.apply(latest_digest(rule))
        end
      end

      clear_digests

      digest.save
    end

    # Run only those rules with a specific bookmark.
    #
    # marks - Bookmark names. [Array<String>].
    #
    # Returns nothing.
    def run_bookmarks(*marks)
      system.rules.each do |rule|
        case rule
        when Book
          book = rule
          book.rules.each do |rule|
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

    # get digest by name, if it doesn't exit create a new one.
    def digest(name=nil)
      @digests[name] ||= Digest.new(:ignore=>ignore, :name=>name)
    end

    # Get the most recent digest for a given rule.
    #
    # Returns [Digest]
    def latest_digest(rule)
      name = Digest.latest(*rule.bookmarks)
      digest(name)
    end

    # Start with a clean slate by remove the digest.
    #
    # Returns nothing.
    def fresh_digest(*marks)
      if marks.empty?
        clear_digests
      else
        marks.each do |mark|
          d = @digests.delete(mark)
          d.remove if d
        end
      end
    end

    # Clear away all digests but the main digest.
    #
    # Returns nothing.
    def clear_digests
      Digest.clear_digests
      @digests = {}
    end

    # Save digests for given bookmarks.
    #
    # Returns nothing.
    def save_digests(*bookmarks)
      bookmarks.each do |mark|
        digest(mark).save
      end
    end

    #
    #def save_pid
    #  File.open('.ergo/pid', 'w') do |f|
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
    #if config = Ergo.rc_config
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
