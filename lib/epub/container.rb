=begin
Utilities for dealing with the mimetype and container file for an epub project.
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
