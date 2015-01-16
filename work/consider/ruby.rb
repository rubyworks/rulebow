
      # Shell out to current ruby command.
      #
      # @return [Boolean] Success of shell call.
      def ruby(*argv)
        system(ruby_command, *argv)
      end

      # Get current ruby shell command.
      #
      # @return [String] Ruby shell command.
      def ruby_command
        @ruby_command ||= (
          require 'rbconfig'
          ENV['RUBY'] ||
            File.join(
              RbConfig::CONFIG['bindir'],
              RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT']
            ).sub(/.*\s.*/m, '"\&"')
        )
      end


