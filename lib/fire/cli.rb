require 'fire/core_ext'
require 'fire/session'

module Fire

  #
  class CLI

    #
    def self.run(argv=ARGV)
      new(argv).run
    end

    #
    def self.autorun(argv=ARGV)
      new(argv).autorun
    end

    # Initialize new instance of Fire::CLI.
    def initialize(argv=ARGV)
      @argv = argv
    end

    # Returns session instance. [Session]
    def session
      @session ||= Session.new(:watch=>@watch)
    end

    #
    def run
      args = cli_parse
      session.run(args)
    end

    #
    def autorun
      args = cli_parse
      session.autorun(args)
    end

    #
    def cli_parse
      cli @argv,
        "-T" => method(:list_tasks),
        "-w" => method(:watch)
    end

    #
    def list_tasks
      puts "(#{session.root})"
      puts session.task_sheet
      exit
    end

    #
    def watch(seconds)
      @watch = seconds 
    end

  end

end
