module Fire

  class Match < String
    def intialize(string, matchdata)
      replace(string)
      @matchdata = matchdata
    end

    def matchdata
      @matchdata
    end
  end

end
