module Osu

  # Match is a subclass of a string that also stores the 
  # MatchData then matched against it in a Regexp comparison.
  #
  class Match < String
    # Initialize a new instance of Match.
    #
    # string    - The string. [String]
    # matchdata - The match data. [MatchData]
    #
    def intialize(string, matchdata)
      replace(string)
      @matchdata = matchdata
    end

    # The match data that resulted from
    # a successful Regexp against the string.
    #
    # Returns [MatchData]
    def matchdata
      @matchdata
    end
  end

end
