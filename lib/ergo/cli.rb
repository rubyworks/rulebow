module Ergo

  ##
  # Fire's command line interface.
  #
  class CLI

    # Fire her up!
    def self.fire!(argv=ARGV)
      new(argv).fire!
    end

    # Initialize new instance of Ergo::CLI.
    # If `argv` is not provided than ARGV is uses.
    #
    # argv - Command line argument. [Array<String>]
    #
    # Returns nothing.
    def initialize(argv=nil)
      begin
        require 'dotopts'
      rescue LoadError
      end

      @argv = Array(argv || ARGV)

      @script = nil
      @watch  = nil
      @fresh  = false
    end

    # Returns runner instance. [Runner]
    def runner
      @runner ||= (
        Runner.new(
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
    def fire!(argv=ARGV)
      $DEBUG = argv.include?('--debug') || $DEBUG
      return fire if $DEBUG
      begin
        fire
      rescue => err
        puts "ergo: error #{err}"
      end
    end

    # Fire her up!
    def fire
      args = cli_parse

      ensure_options(args)

      #if args.first == 'init' && !runner.root?
      #  init_project(*args)
      #end

      case @command
      when :list
        print_rules(*args)
      else
        runner.run(*args)
      end
    end

    # Parse command line arguments with just the prettiest
    # little CLI parser there ever was.
    def cli_parse
      @command = nil

      cli @argv,
        "-R --rules"  => lambda{ @command = :list },
        "-a --auto"   => method(:watch=),
        "-f --fresh"  => method(:fresh!),
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
  
    # Set the "watch" period --the rate at which
    # autofiring of occurs.
    #
    # Returns [Fixnum[
    def watch=(seconds)
      @watch = seconds.to_i
    end

    # Use alternate ergo script.
    #
    # Returns [Array]
    def script=(script)
      @script = script.to_s
    end

    #
    #
    # Returns nothing.
    def init_project(*args)
      FileUtils.mkdir_p('.ergo')
    end

    # Print out a list of availabe manual triggers.
    #
    # Returns nothing.
    def print_rules(*names)
      names = nil if names.empty?

      list = []
      runner.rules.each do |rule|
        if Book === rule
          rule.rules.each do |r|
            next unless names.any?{ |n| r.mark?(n) } if names
            list << r.to_a
          end
        else         
          next unless names.any?{ |n| rule.mark?(n) } if names
          list << rule.to_a
        end
      end

      list.reject!{ |desc, marks, prv| desc.to_s == "" }

      puts "(#{runner.root})"

      i = 1
      list.each do |desc, marks, prv|
        if marks.empty?
          puts "%4d. %s%s" % [i, desc, prv ? '*' : '']
        else
          puts "%4d. %s%s (%s)" % [i, desc, prv ? '*' : '', marks.join(' ')]
        end
        i += 1
      end

      exit
    end

  end

end
