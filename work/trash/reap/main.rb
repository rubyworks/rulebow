#!/usr/bin/env ruby

ignore 'pages', 'doc', 'site', 'log'

##
# Default
#
set :default => [:index, :manifest, :demo]

##
# Release
#
# TODO: How to force all tests to be run?
#
set :release => [:index, :demo, :manifest, :doc]

