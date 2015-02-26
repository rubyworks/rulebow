#!/usr/bin/env ruby

#
# Shomen documentation. (NOT USED PRESENTLY)
#

book :doc do
  desc "generate shomen documentation"

  rule :shomen_docs_needed? => :update_shomen_docs

  def shomen_docs_needed?
    files = `mast -b --no-head`.split("\n")
    doc_file = "web/doc/#{project.name}-#{project.version}.json"
    ! FileUtils.uptodate?(doc_file, files)
  end

  def update_shomen_docs
    shell "shomen-yard > web/doc/#{project.name}-#{project.version}.json"
  end
end


# Access to project metadata, if needed.
def project
  @project ||= (
    require 'yaml'
    index = YAML.load_file('.index')
    Struct.new('Project', *index.keys).new(*index.values)
  )
end

