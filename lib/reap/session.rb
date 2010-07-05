require 'reap/system'

module Reap

  #
  class Session

    #
    attr :system

    #
    def initialize
      @system = System.new
    end

    # TODO: narrow the selection a bit?
    def scripts
      @scripts ||= (
        files = []
        files += Dir.glob('reapfile', File::FNM_CASEFOLD)
        files += Dir.glob('task{,s}/*.reap', File::FNM_CASEFOLD)
        files += Dir.glob('.config/reap/rules/*.reap', File::FNM_CASEFOLD)
        files
      )
    end

    #
    def execute
      eval
      run
    end

    #
    def eval
      scripts.each do |file|
        script = File.read(file)
        system.eval(script)
      end
    end

    #
    def run
      system.run
    end

  end

end
