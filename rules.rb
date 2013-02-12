#!/usr/bin/env ruby

require 'yaml'

def project
  @project ||= (
    index = YAML.load_file('.index')
    Struct.new('Project', *index.keys).new(*index.values)
  )
end

state :manifest_outofdate do
  ! system "mast --quiet --recent"
end

# Mast handles manifest updates.
rule manifest_outofdate do
  sh "mast -u"
end

state :need_shomen do
  files = `mast -b --no-head`.split("\n")
  doc_file = "doc/#{project.name}-#{project.version}.json"
  ! FileUtils.uptodate?(doc_file, files)
end

rule need_shomen do
  cmd = "shomen-yard > doc/#{project.name}-#{project.version}.json"
  sh cmd
end

desc "Generate shomen documentation"
task :shomen => [:say_hi] do
  cmd = "shomen yard > docs/#{project.name}-#{project.version}.json"
  puts cmd #sh cmd
end

task :say_hi do
  puts "Hi!"
end

task :test do
  puts "Write some tests!!!"
end
