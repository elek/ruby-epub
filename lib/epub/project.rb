=begin
A "project" directory for an EPub publication, similar 
in concept to a project in Mobipocket Creator.
=end
require 'epub/opf'
require 'epub/ncx'
require 'epub/container'

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
        DEFAULT_TITLE = 'TITLE'
        DEFAULT_LANGUAGE = 'en-US'

        attr_reader :directory, :title, :opf_file, :ncx_file, :identifier

        # Constructor
        # 
        # Parameters:
        # - directory : Epub project directory
        def initialize(directory)
            @directory = directory

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

        # Full path to the project directory.
        #
        # Parameters: 
        # - localpath : if given, prepends the full path
        def fullpath(localpath = '')
            return "#{@directory}/#{localpath}"
        end

        # Reads in data from an existing project
        def initialize_from_existing
            opf_location = ContainerFile.get_opf_path(@directory)

            # The OPF file has a pointer to the TOC file, 
            # the title, and the identifier for this project
            @opf_file = Epub::Opf::OpfFile.new(fullpath(opf_location))
            @title = @opf_file.title
            @identifier = @opf_file.identifier
            ncx_location = @opf_file.toc

            # The NCX file is the last main file to open.
            @ncx_file = Epub::Ncx::NcxFile.new(fullpath(ncx_location))
        end

        # Creates a brand new project, using defaults.
        def create_new_project
            FileUtils.mkdir_p(@directory)

            @ncx_file = Epub::Ncx::NcxFile.new(fullpath(DEFAULT_NCX_FILE))
            @ncx_file.add_metadata('dtb:depth', '1')
            @ncx_file.add_metadata('dtb:totalPageCount', '0')
            @ncx_file.add_metadata('dtb:maxPageNumber', '0')

            @opf_file = Epub::Opf::OpfFile.new(fullpath(DEFAULT_OPF_FILE))
            @opf_file.language = DEFAULT_LANGUAGE
            @opf_file.toc = DEFAULT_NCX_FILE
            @opf_file.add_manifest_item('ncx', DEFAULT_NCX_FILE, 
                                        Epub::Opf::MEDIA_TYPES['ncx'])

            self.identifier = "#{Socket.hostname} [#{Time.now.to_s}]"
            self.title = DEFAULT_TITLE

            Epub::MimeTypeFile.create(@directory)
            Epub::ContainerFile.create(@directory, DEFAULT_OPF_FILE)
        end
    end
end
