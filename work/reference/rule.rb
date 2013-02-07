rulebook :rdoc do

  state :rdoc? do |env|
    outofdate? dir('doc/rdoc').mtime, files(project.loadpath,'**/*')
  end

  rule :rdoc => [:rdoc?] do
    rdoc files('[A-Z]*') + files(project.loadpath,'**/*'), :output=>'doc/rdoc'
  end

  rule :rdoc_reset => [command(:reset)] do
    file('doc/rdoc').mtime = 0
  end

  rule :rdoc_clean => [command(:clean)] do
    file('doc/rdoc').rm_r
  end

end

