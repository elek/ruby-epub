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

A "project" directory for an EPub publication, similar 
in concept to a project in Mobipocket Creator.

TODO: Add unit tests for Project!

=end
require 'epub/opf'
require 'epub/ncx'
require 'epub/container'
require 'epub/templates'

require 'fileutils'
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

        # Sets the language of the project
        def language=(language)
            @opf_file.language = language
        end

        # Adds a creator.
        #
        # Parameters:
        # - name : name of the contributor, in last_name,first_name form
        # - role : role of the creator, defaults to author
        def add_creator(name, role = 'aut')
            @opf_file.add_creator(name, role)
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

                epub_file = "#{File.join(old_dir, File.basename(Dir.pwd).gsub(/[ ,:]/,'_'))}.epub"

                system(%Q(zip -Xr9D '#{epub_file}' mimetype META-INF #{localpath(@opf_file.file)}))
                @opf_file.manifest.values.each do |item|
                    system(%Q(zip -Xr9D '#{epub_file}' '#{item.href}' -x mimetype))
                end
            ensure
                Dir.chdir old_dir
            end
        end

        # Registers a content file with the OPF.
        #
        # Parameters: 
        # - id : unique id for the file 
        # - href : path relative to the directory to the file
        # - add_to_spine : (optional) if true, adds id to the spine; default false
        # - media_type : (optional) media type of the file
        def register_with_opf(id, href, add_to_spine = false, media_type = nil)
            @opf_file.add_manifest_item(id, href, media_type)
            if (add_to_spine) 
                @opf_file.add_spine_itemref(id)
            end
        end

        # Sets up a reference guide item with the OPF.
        #
        def register_guide_reference(type, title, href)
            @opf_file.add_guide_reference(type, title, href)
        end

        # Registers a content file with the NCX.
        #
        # Parameters: 
        # - id : unique id for the navigation point
        # - label : label for the navigation point
        # - src : path relative to the directory to the file
        # - play_order : (optional) the play order; by default, the 
        #                next available in the NCX.
        def register_with_ncx(id, label, src, play_order = nil) 
            if (play_order)
                @ncx_file.insert_navigation_point(id, label, src, play_order)
            else
                @ncx_file.add_navigation_point(id, label, src)
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

        # Localize path with respect to the project, if 
        # appropriate. 
        #
        # Parameters: 
        # - path : removes @directory from the path, raises 
        #          exception if @directory is not part of 
        #          the path
        def localpath(path)
            if (path !~ /^#{@directory}/)
                raise "#{@directory} is not part of path '#{path}'!"
            else
                return path.sub(/^#{@directory}[\/]?/, '')
            end
        end

        # Reads in data from an existing project
        def initialize_from_existing
            opf_location = ContainerFile.get_opf_path(@directory)

            # The OPF file has a pointer to the TOC file, 
            # the title, and the identifier for this project
            @opf_file = Epub::Opf::OpfFile.new(fullpath(opf_location))
            @title = @opf_file.title
            @identifier = @opf_file.identifier

            ncx_location = @opf_file.get_toc_location

            # The NCX file is the last main file to open.
            @ncx_file = Epub::Ncx::NcxFile.new(fullpath(ncx_location))
        end

        # Creates a brand new project, using defaults.
        #
        # If create_template is true, a template file (title.html) is 
        # created in the content directory and registered as part 
        # of the OPF manifest and the NCX file.
        #
        # Parameters:
        # - create_template: create a template file. Default: false
        #
        def create_new_project(create_template = false)
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

            if create_template
                File.open(fullpath(['content', 'title.html']), 'w') do |file|
                    Epub::Templates.writeHtmlTemplate(file, @title)
                end
                register_with_opf('title', 'content/title.html', true)
                register_with_ncx('title', @title, 'content/title.html')
            end
        end
    end
end
