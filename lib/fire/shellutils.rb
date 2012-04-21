module Fire

  module ShellUtils
    def sh(*args)
      puts args.join(' ')
      system(*args)
    end
  end

end
