#
# Update .index file
#

set :index do
  desc "update index file"

  rule 'INDEX.yml' do 
    shell "index -u INDEX.yml"
  end
end

