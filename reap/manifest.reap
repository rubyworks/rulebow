#
# Update Manifest
#
# This uses the mast commandline tool.
#

book :manifest do
  desc "update manifest"

  rule :manifest_outofdate? => :update_manifest

  def manifest_outofdate?
    ! system "mast --quiet --verify"
  end

  def update_manifest
    shell "mast -u"
  end
end

