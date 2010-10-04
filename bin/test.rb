#!/usr/bin/ruby

require 'epub'
require 'zip/zip'

project = Epub::Project.new "/home/elek/test.epub"
print project.title
print project.opf_file.get_dc_meta('creator')[0].value
project.title = "TEST"
project.save()