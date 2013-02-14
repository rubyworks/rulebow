module Fire

  ##
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

    # Fire her up!
    def run
      args = run_cli_parse

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

    # Parse command line arguments with just the prettiest
    # little CLI parser there ever was.
    def run_cli_parse
      @command = nil

      cli @argv,
        "-R --rules"  => lambda{ @command = :list },
        "-c --clean"  => method(:fresh!),
        "-s --script" => method(:script=)
    end

    # Fire her up in autorun mode!
    def autorun
      args = autorun_cli_parse
      session.autorun(args)
    end

    # Parse command line arguments with just the prettiest
    # little CLI parser there ever was.
    def autorun_cli_parse
      @command = nil

      cli @argv,
        "-R --rules"  => lambda{ @command = :list },
        "-f --fresh"  => method(:fresh!),
        "-w --watch"  => method(:watch=),
        "-s --script" => method(:script=)
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

    # Use digest? Default to true.
    #
    # Returns [Boolean]
    def fresh?
      @fresh
    end

    # Ser fresh flag to true.
    #
    # Returns [Boolean]
    def fresh! 
      @fresh = true
    end
  
    # Set the watch wait period.
    #
    # Returns [Fixnum[
    def watch=(seconds)
      @watch = seconds.to_i
    end

    # Use alternate fire script.
    #
    # Returns [Array]
    def script=(script)
      @script = script.to_s
    end

    #
    def init_project(*args)
      FileUtils.mkdir_p('.fire')
    end

  end

end
