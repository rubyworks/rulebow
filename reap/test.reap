##
# Unit Testing
#
book :test do
  desc "run unit tests"

  rule 'test/case_*.rb'         => :test
  rule 'test/helper.rb'         => :test_all
  rule /^lib\/(.*?)\.rb$/       => :test_match
  rule /^lib\/ergo\/(.*?)\.rb$/ => :test_match

  def test(*paths)
    shell "ruby-test #{gem_opt} -Ilib:test #{paths.flatten.join(' ')}"
  end

  def test_all
    test(*Dir['test/**/case_*.rb'])
  end

  def test_match(m)
    test("test/case_#{m[1]}")
  end

  def gem_opt
    defined?(::Gem) ? "-rubygems" : ""
  end
end

