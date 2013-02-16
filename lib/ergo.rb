# ruby standard library
require 'fileutils'
require 'digest/sha1'
require 'ostruct'

# third party library
require 'notify'

# internal library
require_relative 'ergo/core_ext'
require_relative 'ergo/match'
require_relative 'ergo/shellutils'
require_relative 'ergo/state'
require_relative 'ergo/rule'
require_relative 'ergo/ignore'
require_relative 'ergo/digest'
require_relative 'ergo/book'
require_relative 'ergo/system'
require_relative 'ergo/runner'
require_relative 'ergo/cli'
