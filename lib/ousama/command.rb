require 'ousama/session'
require 'clap'

module Ousama

  #
  class Command

    #
    def self.run(*argv)
      new.execute(*argv)
    end

    #
    def execute(*argv)
      parse
      session.execute(argv)
    end

    #
    def session
      @session ||= Session.new
    end

    #
    def parse
      Clap.run ARGV,
        "-T" => method(:list_tasks)
    end

    #
    def list_tasks
      puts "(#{session.root})"
      puts session.task_sheet
      exit
    end

  end

end

