require 'rc/interface'

RC.run('ou') do |config|
  Ousama.rc_config = config
end

class << Ousama
  attr_accessor :rc_config
end

