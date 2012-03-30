require 'reap/system'
require 'reap/digest'
require 'fileutils'

module Reap

  #
  ROOT_INDICATORS = %w{.ruby *.reap Reapfile .gemspec *.gemspec .git .hg _darcs}

  # Where to search for reap files.
  SEARCH_DIRECTORIES = %w{. .reap reap task tasks}

  #
  class Session

    IGNORE_FILE = '.reap/ignore'

    #
    attr :system

    #
    def initialize()
    end

    # TODO: load configuration


    # Any file called "Reapfile" with or without an `.rb` extension,
    # or any file with a `.reap` extension, or starting with `reap.`
    # is take as a reap script.
    def scripts
      @scripts ||= (
        dirs = '{' + SEARCH_DIRECTORIES.join(',') + '}'
        files = []
        files += Dir.glob('reapfile{,.rb}', File::FNM_CASEFOLD)
        files += Dir.glob(dirs + '/*.reap', File::FNM_CASEFOLD)
        files += Dir.glob(dirs + '/reap.*', File::FNM_CASEFOLD)
        files
      )
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

    # If a rule explicitly returns `false`, execution of reap stops.
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
    #  '.reap/.digest'
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
      layout = "reap %-#{max}s  # %s"
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
          if ROOT_INDICATORS.any?{ |g| Dir.glob(File.join(d, g)).first }
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
