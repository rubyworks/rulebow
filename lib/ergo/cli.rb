module Osu

  ##
  # Fire's command line interface.
  #
  class CLI

    # Fire her up!
    def self.execute(command, argv=ARGV)
      new(argv).execute(command)
    end

    # Initialize new instance of Osu::CLI.
    # If `argv` is not provided than ARGV is uses.
    #
    # argv - Command line argument. [Array<String>]
    #
    # Returns nothing.
    def initialize(argv=nil)     
      require 'dotopts'

      @argv = Array(argv || ARGV)

      @script = nil
      @watch  = nil
      @fresh  = false
    end

    # Returns session instance. [Session]
    def session
      @session ||= (
        Session.new(
          :script => @script,
          :fresh  => @fresh,
          :watch  => @watch
        )  
      )
    end

    # Execute command.
    #
    # command - Which command to execute.
    #
    # Returns nothing.
    def execute(command, argv=ARGV)
      $DEBUG = ARGV.include?('--debug') || $DEBUG
      if $DEBUG
        send(command)
      else
        begin
          send(command)
        rescue => err
          puts "osu: error #{err}"
        end
      end
    end

    # Fire her up!
    def fire
      args = cli_parse_run

      ensure_options(args)

      #if args.first == 'init' && !session.root?
      #  init_project(*args)
      #end

      case @command
      when :list
        list_rules(*args)
      else
        session.run(args)
      end
    end

    # Fire her up in autorun mode!
    def autofire
      args = cli_parse_autorun

      ensure_options(args)

      session.autorun(args)
    end

    # Parse command line arguments with just the prettiest
    # little CLI parser there ever was.
    def cli_parse_run
      @command = nil

      cli @argv,
        "-R --rules"  => lambda{ @command = :list },
        "-f --fresh"  => method(:fresh!),
        "-s --script" => method(:script=),
        "   --debug"  => method(:debug!)
    end

    # Parse command line arguments with just the prettiest
    # little CLI parser there ever was.
    def cli_parse_autorun
      @command = nil

      cli @argv,
        "-R --rules"  => lambda{ @command = :list },
        "-f --fresh"  => method(:fresh!),
        "-w --watch"  => method(:watch=),
        "-s --script" => method(:script=),
        "   --debug"  => method(:debug!)
    end

    #
    def ensure_options(args)
      erropts = args.select{ |a| a.start_with?('-') }
      unless erropts.empty?
        raise "unsupported options #{erropts.join(' ')}" 
      end
    end

    # Print out a list of availabe manual triggers.
    def list_rules(*names)
      puts "(#{session.root})"
      names = nil if names.empty?

      session.rules.each do |rule|
        case rule
        when Book
          book = rule
          book.rules.each do |r|
            next if r.description.to_s == ""
            if names
              next unless names.include?(book.name.to_s) || names.any?{ |n| r.mark?(n) }
            end
            puts "* %s (%s)" % [r, ([book.name] + r.bookmarks).join(' ')]
          end
        else
          next if rule.description.to_s == ""
          if names
            next unless names.any?{ |n| rule.mark?(n) }
          end
          if rule.bookmarks.empty?
            puts "* %s" % [rule]
          else
            puts "* %s (%s)" % [rule, rule.bookmarks.join(' ')]
          end
        end
      end

      exit
    end

    # Shall we make a fresh start of it, and remove all digests?
    #
    # Returns [Boolean]
    def fresh?
      @fresh
    end

    # Set fresh flag to true.
    #
    # Returns [Boolean]
    def fresh! 
      @fresh = true
    end

    # Shall we make a fresh start of it, and remove all digests?
    #
    # Returns [Boolean]
    def debug?
      @debug
    end

    # Set debug flag to true.
    #
    # Returns [Boolean]
    def debug! 
      @debug = true
    end
  
    # Set the watch wait period.
    #
    # Returns [Fixnum[
    def watch=(seconds)
      @watch = seconds.to_i
    end

    # Use alternate osu script.
    #
    # Returns [Array]
    def script=(script)
      @script = script.to_s
    end

    #
    def init_project(*args)
      FileUtils.mkdir_p('.osu')
    end

  end

end