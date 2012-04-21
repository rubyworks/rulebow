require 'fire/session'
require 'clap'

module Fire

  #
  class Command

    #
    def self.run(*argv)
      new.execute(*argv)
    end

    #
    def execute(*argv)
      args = parse
      session.execute(args)
    end

    #
    def session
      @session ||= Session.new(:watch=>@watch)
    end

    #
    def parse
      Clap.run ARGV,
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

