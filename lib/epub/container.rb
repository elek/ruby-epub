=begin

Copyright 2008 Arachne Jericho <arachne.jericho@gmail.com>

This file is part of RubyEpub.

RubyEpub is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

RubyEpub is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with RubyEpub.  If not, see <http://www.gnu.org/licenses/>.

=end
=begin rdoc

Utilities for dealing with the OEBPS Container file and the 
mimetype file.

=end
require 'FileUtils'
require 'rexml/document'

module Epub
    module ContainerFile

        #
        # Creates a brand new container file, with the given 
        # directory as the base (e.g., the directory that contains
        # the META-INF directory). 
        #
        # Parameters:
        # - directory : base directory 
        # - opfpath : path to the OPF file relative to base directory
        #
        def ContainerFile.create(directory, opfpath)
            FileUtils.mkdir_p("#{directory}/META-INF")
            File.open("#{directory}/META-INF/container.xml", "w") do |file|
                file.puts <<-END
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
   <rootfiles>
      <rootfile full-path="#{opfpath}" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
                END
            end
        end

        #
        # Locates the container file in the given base 
        # directory and returns the path to the OPF file.
        #
        def ContainerFile.get_opf_path(directory)
            file = File.new "#{directory}/META-INF/container.xml"
            doc = REXML::Document.new file
            path = doc.elements['container/rootfiles/rootfile'].attributes['full-path']
            file.close
            return path
        end
    end

    module MimeTypeFile
        #
        # Creates an epub mimetype file in the given base 
        # directory.
        #
        def MimeTypeFile.create(directory)
            File.open("#{directory}/mimetype", "w") do |file|
                file.puts 'application/epub+zip'
            end
        end
    end
end
