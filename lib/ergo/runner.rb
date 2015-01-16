module Ergo

  # Runner is the main class which controls execution.
  #
  class Runner
    # Default script
    CONFIG_SCRIPT = "{E,e}rgofile{,.rb}"

    # Initialize new Runner instance.
    #
    # Returns nothing.
    def initialize(options={})
      self.config = options[:config] #|| CONFIG_SCRIPT
      self.ignore = options[:ignore]
      #self.root   = options[:root]

      self.trial  = options[:trial]
      self.fresh  = options[:fresh]
      self.watch  = options[:watch]

      locate_root

      @system = System.new(:root=>root, :config=>config, :ignore=>ignore)
    end

    # Locate project root. This method ascends up the file system starting
    # as the current working directory looking for a `.ergo` directory.
    # When found, the directory in which it is found is returned as the root.
    # It is also memoized, so repeated calls to this method will not repeat
    # the search.
    #
    # Returns [String]
    def root
      @root
    end

    #
    def locate_root
      d = Dir.pwd
      while d != home && d != '/'
        f = Dir.glob(File.join(d, CONFIG_SCRIPT)).first
        if f
          @root   = d
          @config = f
          break
        end
        d = File.dirname(d)
      end
      raise(RootError, "cannot locate project root") unless @root
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
    def config
      @config ||= Dir[CONFIG_SCRIPT].first
    end

    # Set config script.
    def config=(script)
      @config = script
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

    # Set the root directory.
    #
    # Returns [String]
    #def root=(dir)
    #  @root = dir if dir
    #end

    # Instance of {Ergo::System}.
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
        run_book(name)
      end
    end

    # Run rules periodically.
    #
    # Returns nothing.
    def autorun(name)
      Dir.chdir(root) do
        fresh_digest(name) if fresh?

        trap("INT") { puts "\nPutting out the fire!"; exit }

        puts "Fire started! (pid #{Process.pid})"

        loop do
          run_book(name)
          sleep(watch)
        end
      end
    end

    # Run a specific rulebook.
    #
    # name - Nmae of book. [String].
    #
    # Returns nothing.
    def run_book(name)
      books = book_chain(name)
      books.each do |book|
        run_rules(book)
        digest.save(book)
      end
    end

    # Run all books.
    #
    def run_all
      run_rules(system)
      digest.clear
      digest.save
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
        rule.apply(digest[book])
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
        chain = book_chain(name)
        chain.each do |n|
          digest.remove(n)
        end
      else
        digest.clear_all
      end
    end

    # Save digests for given books.
    #
    # Returns nothing.
    def save_digests(*books)
      books.each do |name|
        digest.save(name)
      end
    end

    # Get book instance for a given command.
    def book_chain(name)
      book = verify_book!(name)
      chain = []
      build_chain(book, chain)
      chain.uniq
    end

    #
    def build_chain(book, chain=[])
      book.chain.each do |name|
        verify_book!(name)
        build_chain(books[name], chain)
      end
      chain << book
      return chain
    end

    #
    def verify_book!(name)
      name = name.to_sym
      unless books.key?(name)
        raise(ArgumentError, "unknown book name -- #{name}")
      end
      books[name]
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
