require 'rulebow'

When 'iven a @system and a @ruleset defined with' do |text|
  @system = Rulebow::System.new(:root=>Dir.pwd, :statefile=>'example.state')
  @ruleset = (
    @system.ruleset(:example) do
      module_eval(text)
    end
  )
end

