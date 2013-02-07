# TODO: When RC api is stable...

require 'rc/interface'

class << Fire
  attr_accessor :rc_config
end

RC.run('autofire') do |config|
  Fire.rc_config = config
end


