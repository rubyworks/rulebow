require 'rc/interface'

class << Ousama
  attr_accessor :rc_config
end

RC.run('ou') do |config|
  Ousama.rc_config = config
end

