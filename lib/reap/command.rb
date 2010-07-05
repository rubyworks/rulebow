module Reap

  #
  class Command

    #
    def self.main
      new.execute
    end

    #
    def execute
      session = Session.new
      session.execute
    end

  end

end
