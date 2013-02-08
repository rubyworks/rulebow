
When 'iven a @system defined' do |text|
  @system = Fire::System.new
  @system.module_eval(text)
end
