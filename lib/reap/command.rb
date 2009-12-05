require 'reap/session'

module Reap

  class Command
    def self.run
      new.run
    end

    #
    def run
      session = Session.new
      session.execute
    end
  end

end

