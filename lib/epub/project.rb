=begin
A "project" directory for an EPub publication, similar 
in concept to a project in Mobipocket Creator.
=end
require 'epub/opf'
require 'epub/ncx'
require 'FileUtils'
require 'ftools'
require 'socket'
require 'time'

module Epub

    # An Epub project with its attendant source files.
    # The main goal of this class is to coordinate metadata 
    # across multiple files (in particular, the OPF and the NCX).
    class Project
        DEFAULT_OPF_FILE = 'metadata.opf'
        DEFAULT_NCX_FILE = 'toc.ncx'
        DEFAULT_LANGUAGE = 'en-US'

        attr_reader :directory, :title, :opf_file, :ncx_file, :identifier

        # Constructor
        # 
        # Parameters:
        # - directory : Epub project directory
        # - title : Title of the work
        def initialize(directory, title)
            @directory = directory
            @title = title

            if (File.exists? @directory)
                raise "'#{@directory}' is not a directory" if (File.directory? @directory)
                initialize_from_existing
            else
                create_new_project
            end
        end

        # Sets the title of the project.
        def title=(title)
            @title = title
            @opf_file.title = title
            @ncx_file.title = title
        end

        # Sets the identifier of the project.
        def identifier=(identifier)
            @identifier = identifier
            @opf_file.identifier = identifier
            @ncx_file.identifier = identifier
        end

        private

        # Reads in data from an existing project
        def initialize_from_existing
            # Find the container file, which points to the OPF file.
            doc = REXML::Document.new "#{@directory}/META-INF/container.xml"
            opf_location = doc.elements['container/rootfiles/rootfile'].attributes['full-path']

            # The OPF file has a pointer to the TOC file, 
            # the title, and the identifier for this project
            @opf_file = Epub::Opf::OpfFile.new(opf_location)
            @title = @opf_file.title
            @identifier = @opf_file.identifier
            ncx_location = @opf_file.toc

            # The NCX file is the last main file to open.
            @ncx_file = Epub::Ncx::NcxFile.new(ncx_location)
        end

        # Creates a brand new project, using defaults.
        def create_new_project
            FileUtils.mkdir_p(@directory)

            create_identifier
            create_ncx_file
            create_opf_file

            create_mimetype_file
            create_container_file
        end

        # Create a basic book id based on the current hostname 
        # and timestamp.  
        def create_identifier
            @identifier = "#{Socket.hostname} [#{Time.now.to_s}]"
        end

        # Creates the mimetype marker file
        def create_mimetype_file
            File.open("#{@directory}/mimetype", "w") do |file|
                file.puts 'application/epub+zip'
            end
        end

        # Creates a container file
        def create_container_file
            File.Utils.mkdir_p("#{@directory}/META-INF")
            File.open("#{@directory}/META-INF/container.xml", "w") do |file|
                file.puts <<-END
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
   <rootfiles>
      <rootfile full-path="#{@opf_file.file}" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
                END
            end
        end

        # Create NCX file from absolute scratch (using defaults)
        def create_ncx_file
            @ncx_file = Epub::Ncx::NcxFile.new DEFAULT_NCX_FILE

            @ncx_file.identifier = @identifier
            @ncx_file.add_metadata('dtb:depth', '1')
            @ncx_file.add_metadata('dtb:totalPageCount', '0')
            @ncx_file.add_metadata('dtb:maxPageNumber', '0')

            @ncx_file.title = @title
        end

        # Create OPF file from absolute scratch (using defaults)
        def create_opf_file
            @opf_file = Epub::Opf::OpfFile.new DEFAULT_OPF_FILE
            
            @opf_file.title = @title
            @opf_file.identifier = @identifier
            @opf_file.language = DEFAULT_LANGUAGE
            @opf_file.toc = DEFAULT_NCX_FILE

            @opf_file.add_manifest_item('ncx', DEFAULT_NCX_FILE, 
                                        Epub::Opf::MEDIA_TYPES['ncx'])
        end
    end
end
