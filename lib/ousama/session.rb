require 'ousama/system'
require 'ousama/digest'
require 'fileutils'

module Ousama

  #
  ROOT_INDICATORS = %w{.ruby .ou rulefile.rb rulefile .git .hg _darcs .gemspec *.gemspec}

  # This file can be used as an alternative to using the #ignore method 
  # to define what paths to ignore.
  IGNORE_FILE = '.ou/ignore'

  #
  class Session

    #
    attr :system

    #
    def initialize()
    end

    # TODO: load configuration


    # Any file called "Rulefile" or ".ou/rulefile.rb".
    def scripts
      @scripts ||= (
        files = []
        files += Dir.glob('.ou/rulefile.rb', File::FNM_CASEFOLD)
        files += Dir.glob('rulefile{,.rb}', File::FNM_CASEFOLD)
        files
      )
    end

    #
    def rc?
      Dir.glob('{.c,c,C}onfig{.rb,}').first
    end

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

    def system
      @system ||= System.new(ignore, *scripts)
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

    # Run the rea session.
    #
    def run(argv)
      if argv.size > 0
        run_task(*argv)
      else
        run_rules
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
    #  '.ou/digest'
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

    # Locate project root. This method ascends up the file system starting
    # as the current working directory looking for `ROOT_INDICATORS`. When
    # a match is found, the directory in which it is found is returned as
    # the root. It is also memoized, so repeated calls to this method will
    # not repeat the search.
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
