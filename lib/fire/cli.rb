require 'fire/core_ext'
require 'fire/session'

module Fire

  # Fire's command line interface.
  #
  class CLI

    # Fire her up!
    def self.run(argv=ARGV)
      new(argv).run
    end

    # Fire her up in autorun mode!
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

    # Fire her up!
    def run
      args = cli_parse
      session.run(args)
    end

    # Fire her up in autorun mode!
    def autorun
      args = cli_parse
      session.autorun(args)
    end

    # Parse command line arguments with just the prettiest
    # little CLI parser there ever was.
    def cli_parse
      cli @argv,
        "-T" => method(:list_tasks),
        "-w" => method(:watch)
    end

    # Print out a list of availabe manual triggers.
    def list_tasks
      puts "(#{session.root})"
      puts session.task_sheet
      exit
    end

    # Set the watch wait period.
    def watch(seconds)
      @watch = seconds 
    end

  end

end
