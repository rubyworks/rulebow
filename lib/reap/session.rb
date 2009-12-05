require 'reap/engine'

module Reap

  class Session

    attr :engine

    #
    def initialize
      @engine = Engine.new
    end

    #
    def scripts
      @scripts ||= (
        files = []
        files += Dir.glob('reapfile', File::FNM_CASEFOLD)
        files += Dir.glob('task{,s}/*.reap', File::FNM_CASEFOLD)
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
        engine.eval(script)
      end
    end

    #
    def run
      engine.run
    end

  end

end
