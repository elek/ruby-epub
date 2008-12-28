=begin rdoc
Limited representation of the Navigation Control File for XML 
applications (NCX), for minimal Epub support.

Documentation of the format: http://www.daisy.org/z3986/2005/Z3986-2005.html#NCX

Support includes: 

* meta tags in the head section
* docTitle
* navMap and navPoint, navLabel, content
* nested navPoints

=end
require 'rexml/document'

module Epub
    module Ncx

        # A metadata element in the head of an NCX file
        class MetaData
            attr_accessor :name, :content
            # Constructor
            #
            # Parameters:
            # - name : name of this piece of metadata
            # - content : value of this piece of metadata
            def initialize(name, content)
                @name = name
                @content = content
            end
            def to_s
                return %Q(<meta name="#{@name}" content="#{@content}"/>)
            end
        end

        # A navigation point in an NCX file, and they usually 
        # look like: 
        # 
        # <navPoint id="article-5" playOrder="28">
        #   <navLabel>
        #     <text>Article V. [The Amendment Process]</text>
        #   </navLabel>
        #   <content src="content/article-5.html"/>
        #
        #   ... multiple nested navPoints ...
        #
        # </navPoint>
        class NavigationPoint
            attr_accessor :id, :play_order, :label, :content, :points

            # Constructor.
            #
            # Parameters: 
            # - id : unique (to this map) id of the navigation point
            # - play_order : sequential play order of this navigation point
            # - label : label of the navigation point
            # - content : location of the navigation point's content
            # - points : list of NavigationPoint instances (optional)
            def initialize(id, play_order, label, content, points = [])
                @id = id
                @play_order = play_order
                @label = label
                @content = content
                @points = points
            end

            def to_s
                s = <<-END
<navPoint id="#{@id}" playOrder="#{@play_order}">
  <navLabel>
    <text>#{@label}</text>
  </navLabel>
  <content src="#{@content}"/>
                END
                @points.each { |point| s += point.to_s }
                s += <<-END
</navPoint>
                END
                return s
            end
        end

        # Representation of the data in an NCX file.
        class NcxFile
            attr_accessor :file, :metadata, :title, :map, :dtb_uid

            # Constructor.
            #
            # Parameters:
            # - file: filename. If the file exists, read in the values.
            def initialize(file)
                @file = file
                create_from_scratch

                if (File.exists? @file)
                    create_from_file
                end
            end

            def add_metadata(name, content)
                meta = MetaData.new(name, content)
                @metadata[name] = meta
            end
            def delete_metadata(name)
                @metadata.delete name
            end

            def identifier
                return @dtb_uid.content
            end
            def identifier=(book_id)
                @dtb_uid.content = book_id
            end

            # Writes this NCX file to disk, making a backup of the 
            # previous file if it existed.
            def write
                newfile = "#{@file}.new"

                File.open(newfile, "w") do |file|
                    file.puts <<-END
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    #{@dtb_uid}
                    END
                    @metadata.keys.sort.each { |key| file.puts @metadata[key] }
                    file.puts <<-END
  </head>
  <docTitle>
    <text>#{@title}</text>
  </docTitle>
  <navMap>
                    END
                    @map.each { |point| file.puts point }
                    file.puts <<-END
  </navMap>
</ncx>
                    END

                end

                if (File.exists? @file)
                    backupfile = "#{@file}.#{Time.new}.bak"
                    File.rename(@file, backupfile)
                end
                File.rename(newfile, @file)
            end

            private

            def create_from_scratch
                @dtb_uid = MetaData.new('dtb:uid', '')
                @metadata = {}
                @title = ''
                @map = []
            end

            # Helper function for create_from_file that recursively 
            # creates navigation points.
            #
            # Parameters: 
            # - element : current XML element representing a navigation point
            def create_navpoint(element)
                navPoint = NavigationPoint.new(element.attributes['id'],
                                               element.attributes['playOrder'], 
                                               element.elements['navLabel/text'].text,
                                               element.elements['content'].attributes['src'])
                element.elements.each('navPoint') do |e|
                    navPoint.points.push create_navpoint(e)
                end

                return navPoint
            end

            def create_from_file
                File.open(@file) do |file|
                    doc = REXML::Document.new file

                    doc.elements.each('ncx/head/meta') do |e|
                        meta = MetaData.new(e.attributes['name'], e.attributes['content'])
                        if (e.attributes['name'] == 'dtb:uid')
                            @dtb_uid.content = meta.content
                        else
                            @metadata[meta.name] = meta
                        end
                    end

                    @title = doc.elements['ncx/docTitle/text'].text

                    doc.elements.each('ncx/navMap/navPoint') do |e|
                        @map.push(create_navpoint(e))
                    end

                end
            end
        end
    end
end
