#
# QED Demos
#

set :demo do
  desc "run demos"

  rule 'demo/**/*.md'        => :demo
  rule 'lib/**/*.rb'         => :demo_all
  rule 'demo/test_helper.rb' => :demo_all

  def demo(*files)
    #files = ["demo/**/*.md"] if files.empty?
    shell "bundle exec qed " + files.join(" ")
  end

  def demo_all
    demo "demo/**/*.md"
  end
end

