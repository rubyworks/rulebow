require 'ergo'

When 'iven a @system defined' do |text|
  @system = Ergo::System.new
  @system.module_eval(text)
end

