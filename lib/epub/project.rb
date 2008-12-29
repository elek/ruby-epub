=begin
A "project" directory for an EPub publication, similar 
in concept to a project in Mobipocket Creator.
=end
require 'epub/opf'
require 'epub/ncx'
require 'epub/container'
require 'epub/templates'

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
        DEFAULT_NCX_FILE_ID = 'toc'
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
                raise "'#{@directory}' is not a directory" if (!File.directory? @directory)
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

        # Sets the unique identifier of the project.
        def identifier=(identifier)
            @identifier = identifier
            @opf_file.identifier = identifier
            @ncx_file.identifier = identifier
        end

        # Writes all files using the current state. 
        def save
            @opf_file.write
            @ncx_file.write
        end

        # Compiles the actual epub file.  Saves the project 
        # before proceeding.
        #
        # TODO: use Archive::Zip instead of external command
        def compile
            save

            old_dir = Dir.pwd
            begin
                Dir.chdir @directory

                epub_file = "#{File.join(old_dir, @title.gsub(/'" /, '_'))}.epub"

                # TODO: get all files involved from OPF and add them spec..
                system(%Q(zip -Xr9D '#{epub_file}' mimetype))
                system(%Q(zip -Xr9D '#{epub_file}' * -x mimetype))
            ensure
                Dir.chdir old_dir
            end
        end

        private

        # Full path to the project directory.
        #
        # Parameters: 
        # - localpath : if given, prepends the full path; 
        #               can be an array of path elements.
        def fullpath(localpath)
            return File.join(@directory, *localpath)
        end

        # Reads in data from an existing project
        def initialize_from_existing
            opf_location = ContainerFile.get_opf_path(@directory)

            # The OPF file has a pointer to the TOC file, 
            # the title, and the identifier for this project
            @opf_file = Epub::Opf::OpfFile.new(fullpath(opf_location))
            @title = @opf_file.title
            @identifier = @opf_file.identifier

            # TODO: make this a method of OpfFile
            ncx_location = @opf_file.manifest[@opf_file.toc].href

            # The NCX file is the last main file to open.
            @ncx_file = Epub::Ncx::NcxFile.new(fullpath(ncx_location))
        end

        # Creates a brand new project, using defaults.
        def create_new_project
            FileUtils.mkdir_p(@directory)
            Epub::MimeTypeFile.create(@directory)
            Epub::ContainerFile.create(@directory, DEFAULT_OPF_FILE)

            @ncx_file = Epub::Ncx::NcxFile.new(fullpath(DEFAULT_NCX_FILE))
            @ncx_file.add_metadata('dtb:depth', '1')
            @ncx_file.add_metadata('dtb:totalPageCount', '0')
            @ncx_file.add_metadata('dtb:maxPageNumber', '0')

            @opf_file = Epub::Opf::OpfFile.new(fullpath(DEFAULT_OPF_FILE))
            @opf_file.language = DEFAULT_LANGUAGE
            @opf_file.toc = DEFAULT_NCX_FILE_ID
            @opf_file.add_manifest_item(DEFAULT_NCX_FILE_ID, DEFAULT_NCX_FILE)

            self.identifier = "#{Socket.gethostname} [#{Time.now.to_s}]"
            self.title = DEFAULT_TITLE

            FileUtils.mkdir_p(fullpath('content'))

            # create a first file; should probably be a convenience method!
            File.open(fullpath(['content', 'title.html']), 'w') do |file|
                Epub::Templates.writeHtmlTemplate(file, @title)
            end
            @opf_file.add_manifest_item('title', 'content/title.html')
            # TODO: add navigation point more convenient, like auto-inc 
            # or manipulate otherwise play order
            @ncx_file.map << Epub::Ncx::NavigationPoint.new(
                            'title', '1', @title, 'content/title.html')
        end
    end
end
