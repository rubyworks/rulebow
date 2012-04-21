require 'fire/system'
require 'fileutils'

module Fire

  # Markers to look for to identify a project's root directory.
  ROOT_INDICATORS = %w{.fire rulefile.rb rulefile .ruby .git .hg _darcs .gemspec *.gemspec}

  # This file can be used as an alternative to using the #ignore method 
  # to define what paths to ignore.
  IGNORE_FILE = '.fire/ignore'

  # Session is the main Fire class which controls execution.
  #
  class Session

    #
    #
    #
    def initialize(options={})
      self.watch = options[:watch]

      system.ignore(*ignore)

      scripts.each do |script|
        system.import(script)
      end

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

    #
    # Watch period.
    #
    def watch
      @watch
    end

    #
    # Set watch seconds. Minimum watch time is 1 second.
    # Setting watch before calling #run creates a simple loop.
    # It can eat up CPU cycles so use it wisely. A watch time
    # of 4 seconds is a good time period. If you are patient
    # go for 15 seconds or more.
    #
    def watch=(seconds)
      if seconds
        seconds = seconds.to_i
        seconds = 1 if seconds < 1
        @watch = seconds
      else
        @watch = nil 
      end
    end

    #
    # Instance of {Fire::System}.
    #
    def system
      @system ||= Fire.system #System.new(ignore, *scripts)
    end

    # TODO: load configuration
    #
    #def rc?
    #  Dir.glob('{.c,c,C}onfig{.rb,}').first
    #end

    #
    # Default fire scripts are any file matching "Rulefile" or ".fire/rulefile.rb",
    # case insensitive.
    #
    # @return [Array] List of file paths.
    #
    def scripts
      @scripts ||= (
        files = []
        files += Dir.glob('.fire/rulefile{.rb,}', File::FNM_CASEFOLD)
        files += Dir.glob('rulefile{,.rb}', File::FNM_CASEFOLD)
        files
      )
    end

    # 
    # File globs to ignore.
    #
    # @return [Array] List of file globs.
    #
    def ignore
      @ignore ||= (
        i = []
        if File.exist?(IGNORE_FILE)
          File.read(IGNORE_FILE).lines.each do |line|
            glob = line.strip
            i << glob unless glob.empty?
          end
        end
        i
      )
    end

    #
    def execute(argv=ARGV)
      Dir.chdir(root) do
        run(argv)
      end
    end

    #
    #def eval
    #  scripts.each do |file|
    #    system << file #script = File.read(file)
    #    #system.eval(script)
    #  end
    #end

    # Run the session.
    #
    def run(argv)
      if argv.size > 0
        run_task(*argv)
      else
        if @watch
          trap("INT") { puts "\nEnd Fire Watch."; exit;}
          puts "Start Fire Watch: #{Process.pid}"
          loop do
            run_rules
            sleep(@watch)
          end
        else
          run_rules
        end
      end
    end

    #
    def run_task(name, *args)
      task = system.tasks[name.to_sym]
      task.to_proc.call #(*args)
    end

    # If a rule explicitly returns `false`, execution of ou stops.
    #
    # TODO: Should we drop the `false` and leave abort up to the rules?
    #
    def run_rules
      #session = OpenStruct.new
      system.rules.each do |rule|
        rule.apply
        #if args = rule.active?
        #  #result = rule.call(*args)
        #  #abort "Rule #{rule} terminated." if FalseClass===result
        #  rule.call(*args)
        #end
      end
      save_digest
    end

    #
    def save_digest
      digest = Digest.new(:ignore=>ignore)
      digest.save
    end

    #
    #def digest_file
    #  '.fire/digest'
    #end

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

    # Mapping of tasks from the system.
    def tasks
      system.tasks
    end

    #
    def task_sheet
      max    = tasks.map{|n,t| n.to_s.size}.max.to_i
      layout = "ou %-#{max}s  # %s"
      text   = []
      tasks.each do |name, task|
        text << layout % [name, task.description] if task.description
      end
      text.join("\n")
    end

    #
    # Locate project root. This method ascends up the file system starting
    # as the current working directory looking for `ROOT_INDICATORS`. When
    # a match is found, the directory in which it is found is returned as
    # the root. It is also memoized, so repeated calls to this method will
    # not repeat the search.
    #
    def root
      @root ||= (
        r = nil
        d = Dir.pwd
        while d != home && d != '/'
          if ROOT_INDICATORS.any?{ |g| Dir.glob(File.join(d, g), File::FNM_CASEFOLD).first }
            break r = d
          end
          d = File.dirname(d)
        end
        abort "Can't locate project root." unless r
        r
      )
    end

    # Home directory.
    #
    # @todo: best way to implement?
    def home
      @home ||= File.expand_path('~')
    end

  end

end
