#!/usr/bin/env ruby

require 'yaml'

def project
  @project ||= (
    index = YAML.load_file('.index')
    Struct.new('Project', *index.keys).new(*index.values)
  )
end

rule true do
  puts "Fire Rules!"
end

# Mast handles manifest updates.
state :manifest_outofdate do
  ! system "mast --quiet --verify"
end

desc "update manifest"
rule manifest_outofdate do
  sh "mast -u"
end

desc "run demonstratons"
book :test
rule '{demo/**/*.md,lib/**/*.rb}' do
  sh "qed -Ilib"
end

state :need_shomen do
  files = `mast -b --no-head`.split("\n")
  doc_file = "doc/#{project.name}-#{project.version}.json"
  ! FileUtils.uptodate?(doc_file, files)
end

desc "generate shomen documentation"
book :doc
rule need_shomen do
  cmd = "shomen-yard > doc/#{project.name}-#{project.version}.json"
  sh cmd
end

