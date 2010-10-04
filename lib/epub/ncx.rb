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
      # - play_order : sequential play order of this navigation point; must be number or string that can be converted to number
      # - label : label of the navigation point
      # - content : location of the navigation point's content
      # - points : list of NavigationPoint instances (optional)
      def initialize(id, play_order, label, content, points = [])
        @id = id
        @play_order = play_order.to_i
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
      def initialize(location, file)
        @file = file
        create_from_scratch    
        Zip::ZipInputStream::open(location) { |io|
          while (entry = io.get_next_entry)
            if (entry.name == file)
              create_from_file io.read
              break
            end
          end
        }
        
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
      def write(file)
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

      # Appends an item to the navigation map as a new navigation point.
      # It gets the latest play order available (for giving it a specific
      # playOrder, see insert_navigation_point.
      #
      # Parameters
      # - id : id of the navigation point (needs to be unique to NCX)
      # - label : label of the navigation point
      # - src : src/href of the navigation point content
      #
      # Returns the new navigation point.
      #
      def add_navigation_point(id, label, src)
        playOrder = map.size + 1
        new_np = NavigationPoint.new(id, playOrder, label, src)
        @map << new_np
        return new_np
      end

      # Inserts an item into the navigation map as a new navigation
      # point in a specific position in the play order.  All other
      # items get shifted downwards.
      #
      # Parameters
      # - id : id of the navigation point (needs to be unique to NCX)
      # - label : label of the navigation point
      # - src : src/href of the navigation point content
      # - play_order : play order of the new navigation point. Index
      #                starts at 1.
      #
      # Returns the new navigation point.
      #
      def insert_navigation_point(id, label, src, playOrder)
        new_index = playOrder - 1
        new_size = map.size + 1

        if (playOrder > new_size)
          raise "Play order #{playOrder} is greater than the new map size of #{new_size}!"
        elsif (playOrder <= 0)
          raise "Play order #{playOrder} is 0 or less!"
        else
          new_np = NavigationPoint.new(id, playOrder, label, src)
          map.insert(new_index, new_np)
          map[(new_index + 1)..(map.size)].each do |np|
            np.play_order += 1
          end

          return new_np
        end
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

      def create_from_file(io)
        doc = REXML::Document.new io

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
