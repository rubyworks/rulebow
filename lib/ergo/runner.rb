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

    #
    #
    #
    def commands
      system.commands
    end

    #
    #
    #
    def books
      system.books
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
    def run(command)
      command = command.to_sym if command
      if watch
        autorun(command)
      else
        monorun(command)
      end
    end

  private

    # Returns [Hash]
    attr :digests

    # Run rules once.
    #
    # Returns nothing.
    def monorun(command)
      Dir.chdir(root) do
        fresh_digest(command) if fresh?
        if command
          run_command(command)
        else
          run_default
        end
      end
    end

    # Run rules periodically.
    #
    # Returns nothing.
    def autorun(command)
      Dir.chdir(root) do
        fresh_digest(command) if fresh?

        trap("INT") { puts "\nPutting out the fire!"; exit }
        puts "Fire started! (pid #{Process.pid})"

        if command
          loop do
            run_command(command)
            sleep(watch)
          end
        else
          loop do
            run_default
            sleep(watch)
          end
        end
      end
    end

    # Run default command (i.e. when no command is given).
    # This will run all books if there is no defined default.
    #
    # Returns nothing.
    def run_default
      if commands.key?(:default)
        run_command(:default)
      else
        run_system
      end
    end

    #
    #
    #
    def run_system
      run_rules(system)
      clear_digests
      digest.save
    end

    # Run a specific rulebook.
    #
    # name - Nmae of book. [String].
    #
    # Returns nothing.
    def run_command(name)
      books = command_books(name)
      books.each do |book|
        run_rules(book)
      end
      digest(name).save
    end

=begin
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
=end

    # Run set of rules.
    #
    # Returns nothing.
    def run_rules(book)
      book.rules.each do |rule|
        rule.apply(latest_digest(rule))
      end
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
    def fresh_digest(command_name)
      if command_name
        books = command_books(command_name)
        books.each do |mark|
          d = @digests.delete(mark)
          d.remove if d
        end
      else
        clear_digests
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

    # Get book instance for a given command.
    def command_books(command_name)
      verify_command!(command_name)
      books_names = commands[command_name]
      books_names.map do |n|
        b = books[n.to_sym]
        raise "unknown book -- #{n}" unless b
        b
      end
    end

    #
    def verify_command!(command_name)
      raise UnknownCommand.new(command_name) unless commands.key?(command_name)
    end

    ##
    #
    class UnknownCommand < ArgumentError
      def initialize(command_name)
        super("unknown command name -- #{command_name}")
      end
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
      if system.books.key?(name)
        system.books[name].chain.each do |n|
          complete_chain(n, chain)
        end
      end
      chain << name
      return chain
    end
=end

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
