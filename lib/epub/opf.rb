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

Representation of the Open Packaging Format file and its 
constitute elements, such as meta data (in dc: and the 
deprecated 'meta' flavores), the manifest items, the spine, and 
the guide references.

We don't include 'tours', which are really deprecated.

=end
require 'ftools'
require 'FileUtils'
require 'rexml/document'
require 'ostruct'
require 'time'

module Epub
    module Opf
        # Convenience mapping of the long name of contributer 
        # roles to their short-hand role MARC value.
        MARC = {
            'adapter' => 'adp',
            'annotator' => 'ann',
            'arranger' => 'arr',
            'artist' => 'art', 
            'associated name' => 'asn', 
            'author' => 'aut', 
            'author in quotations' => 'aqt', 
            'author of afterword' => 'aft', 
            'author of introduction' => 'aui', 
            'bibliographic antecedent' => 'ant', 
            'book producer' => 'bkp', 
            'collaborator' => 'clb', 
            'commentator' => 'cmm', 
            'designer' => 'dsr', 
            'editor' => 'edt', 
            'illustrator' => 'ill', 
            'lyricist' => 'lyr', 
            'metadata contact' => 'mdc', 
            'musician' => 'mus', 
            'narrator' => 'nrt', 
            'other' => 'oth', 
            'photographer' => 'pht', 
            'printer' => 'prt', 
            'redactor' => 'red', 
            'reviewer' => 'rev', 
            'sponsor' => 'spn', 
            'thesis advisor' => 'ths', 
            'transcriber' => 'trc', 
            'translator' => 'trl',
        }

        # Convenience mapping of file suffixes (like html) 
        # to media-type strings.
        MEDIA_TYPES = {
            'html' => 'application/xhtml+xml', 
            'xml' => 'application/xhtml+xml',
            'gif' => 'image/gif', 
            'jpg' => 'image/jpeg', 
            'jpeg' => 'image/jpeg', 
            'png' => 'image/png', 
            'css' => 'text/css',
            'ncx' => 'application/x-dbtncx+xml',
        }

        # Convenience listing of allowed reference types
        REFERENCE_TYPES = %w(
            cover title-page toc index glossary acknowledgements 
            bibliography colophon copyright-page dedication 
            epigraph foreward loi lot notes preface text
        )

        # The dublin-core metadata elements in an Opf file. 
        # They tend to look like this:
        #
        # <dc:title>Title</dc:title>
        # <dc:creator opf:file-as="Doe, John" opf:role="aut">John Doe</dc:creator>
        #
        # and so on.
        #
        class Dc
            attr_accessor :name, :value, :attributes

            #
            # Constructor. 
            #
            # Paramters:
            # - name: name of the metadata element, without the dc: prefix
            # - value: value of the metadata element (like Title)
            # - attributes: hash of key => value, where keys are prefixed with the 
            #               opf prefix when necessary.
            # 
            def initialize(name, value, attributes = {})
                @name = name
                @value = value
                @attributes = attributes.delete_if { |key, value| key == 'name' || key == 'content' }
            end
            def to_s
                s = "<dc:#{@name}"
                @attributes.keys.sort.each do |key|
                    attribute = @attributes[key]
                    s += %Q( #{key}="#{attribute}")
                end
                s += ">#{@value}</dc:#{@name}>"
                return s
            end
        end

        # Deprecated form of metadata elements, which look 
        # like this:
        #
        # <meta name="price" content="USD 19.99"/>
        #
        #
        class Meta
            attr_accessor :name, :value, :attributes
            #
            # Constructor.
            # 
            # Parameters:
            # - name: name of the meta element
            # - content: content attribute of the meta element
            # - attributes: key => value hash of any other attributes
            def initialize(name, content, attributes = {})
                @name = name
                @value = content
                @attributes = attributes
            end
            def to_s
                s = %Q(<meta name="#{@name}" content="#{@value}")
                @attributes.keys.sort.each do |key|
                    attribute = @attributes[key]
                    s += %Q( #{key}="#{attribute}")
                end
                s += "/>"
                return s
            end
        end

        # An item in the manifest of an OPF document. 
        # They look like this: 
        #
        # <item id="intro" href="introduction.html" media-type="..."/>
        #
        # All three attributes are required, and no other attributes 
        # are allowed.
        class ManifestItem
            attr_accessor :id, :href, :media_type

            # Constuctor.
            #
            # Parameters: 
            # - id: identifier of the item
            # - href: location relative to the root of the item
            # - media_type: media/mimetype of the item. Can just be the suffix 
            #               if the suffix exists in Epub::Opf::MEDIA_TYPES.
            #               If not present, looks at the suffix of the href.
            def initialize(id, href, media_type = nil)
                @id = id
                @href = href
                if (media_type)
                    self.media_type = media_type
                else
                    if (href =~ /\.([^.]+)$/)
                        self.media_type = MEDIA_TYPES[$1] || $1
                    else
                        raise "No media type given and '#{href}' has no suffix"
                    end
                end
            end
            # Sets the media type. 
            # Parameters: 
            # - media_type: media/mimetype of the item. Can just be the suffix 
            #               if the suffix exists in Epub::Opf::MEDIA_TYPES
            def media_type=(media_type)
                @media_type = MEDIA_TYPES[media_type] || media_type
            end
            def to_s
                return %Q(<item id="#{@id}" href="#{@href}" media-type="#{@media_type}"/>)
            end
        end

        # An item reference in the spine of an OPF file. 
        # It looks like this:
        #
        # <itemref idref="id"/>
        #
        # It has only the idref attribute and can have no other attributes.
        class SpineItemRef
            attr_accessor :idref
            def initialize(idref)
                @idref = idref
            end
            def to_s
                return %Q(<itemref idref="#{@idref}"/>)
            end
        end

        # A reference in the guide of an OPF file. 
        # It looks like this:
        #
        # <reference type="toc" title="Table of Contents" href="toc.html"/>
        #
        # It must have these three attributes and can't have any others.
        class GuideReference
            attr_accessor :type, :title, :href
            def initialize(type, title, href)
                @type = type
                @title = title
                @href = href
            end
            def to_s
                return %Q(<reference type="#{@type}" title="#{@title}" href="#{@href}"/>)
            end
        end


        # An OPF file.
        class OpfFile
            attr_accessor :toc, :file, :dc_title, :dc_language, 
                :dc_identifier, :dc_other, :meta, :manifest, :spine, :guide

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

            # Retrieve all dublin core meta elements with the given name.
            def get_dc_meta(name)
                if (name == 'title')
                    dc_list = [@dc_title]
                elsif (name == 'language')
                    dc_list = [@dc_language]
                else
                    dc_list = @dc_other.select { |item| item.name == name }
                    dc_list.unshift @dc_identifier if (name == 'identifier')
                end

                return dc_list
            end

            # Retrieve all deprecated meta elements with the given name
            def get_deprecated_meta(name)
                return @meta.select { |item| item.name == name }
            end

            def title
                return @dc_title.value
            end
            def title=(title)
                @dc_title.value = title
            end

            def language
                return @dc_language.value
            end
            def language=(language)
                @dc_language.value = language
            end

            def identifier
                return @dc_identifier.value
            end
            def identifier=(identifier)
                @dc_identifier.value = identifier
            end

            def add_manifest_item(id, href, media_type = nil)
                @manifest[id] = ManifestItem.new(id, href, media_type)
            end
            def delete_manifest_item(id)
                @manifest.delete id
            end

            def add_spine_itemref(id)
                @spine << (SpineItemRef.new id)
            end
            # TODO: delete_spine_itemref, insert_spine_itemref

            # TODO: add_guide_reference, delete_guide_reference

            # Writes this OPF file to disk, making a backup of the 
            # previous file if it existed.
            def write
                newfile = "#{@file}.new"

                File.open(newfile, "w") do |file|
                    file.puts <<-END 
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="#{@dc_identifier.attributes['id']}">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
        #{@dc_title}
        #{@dc_language}
        #{@dc_identifier}
                    END
                    @dc_other.each { |item| file.puts item.to_s }
                    @meta.each { |item| file.puts item.to_s }
                    file.puts <<-END
    </metadata>
    <manifest>
                    END
                    @manifest.keys.sort.each { |id| file.puts @manifest[id].to_s }
                    file.puts <<-END
    </manifest>
    <spine toc="#{@toc}">
                    END
                    @spine.each { |item| file.puts item.to_s }
                    file.puts <<-END
    </spine>
    <guide>
                    END
                    @guide.keys.sort.each { |type| file.puts @guide[type].to_s }
                    file.puts <<-END
    </guide>
</package>
                    END
                end

                if (File.exists? @file)
                    backupfile = "#{@file}.#{Time.new}.bak"
                    File.rename(@file, backupfile)
                end
                File.rename(newfile, @file)
            end

            # Return the local path to the file whose id is specified 
            # in the spine in the "toc" attribute (usually the NCX file).
            def get_toc_location
                toc_manifest_item = @manifest[@toc]
                if (!toc_manifest_item) 
                    raise "Manifest item for '#{@toc}' does not exist!"
                else
                    return toc_manifest_item.href
                end
            end

            private

            # Initialize all OPF variables from scratch.
            def create_from_scratch
                # Specially required DC metadata.
                # Although technically there can be multiple 
                # of these, we're going to (for now) assume just 
                # one each, although this can easily be extended.
                @dc_title = Dc.new('title', '')
                @dc_language = Dc.new('language', '')

                # A special case of required metadata: the specified 
                # unique identifier. There can be multiple of these, 
                # which are in @dc_other, but only one that uniquely 
                # identifies this document.
                @dc_identifier = Dc.new('identifier', '', { 'id' => 'bookid' })

                # Other DC metadata items. There 
                # can be multiple of each key type (such as multiple 
                # contributors), so we're using an array instead of 
                # a hash.
                @dc_other = []

                # Deprecated meta-style metadata items. 
                # I think it may be the case that there can 
                # be multiple of each name, so we'll leave it as 
                # an array.
                @meta = []

                # Manifest items, which must be uniquely reference 
                # by id in the file.
                @manifest = {}
                # Spine items, which must be in a specific order and 
                # can be repeated.
                @spine = []
                # Guide items, for which only one guide of each type 
                # can exist.
                @guide = {}

                # The TOC file, which is required for the spine.
                @toc = 'toc'
            end

            # Private helper function for create_from_file. 
            #
            # Can be used to namespace-expand the names of only attributes 
            # that are not in the given namespace.
            #
            # Parameters:
            # - element : REXML element to get attributes from
            # - expand : expand namespaces for attribute names
            # - ns : namespace to not fully expand
            def hash_from_xml_attributes(element, expand = false, ns = '')
                attributes = {}
                element.attributes.each_attribute { |a| 
                    key = a.name
                    key = "#{a.prefix}:#{key}" if (expand && (a.prefix != ns))
                    attributes[key] = a.value
                }
                return attributes
            end

            # Read in values from the @file.
            def create_from_file

                File.open(@file) do |file|
                    doc = REXML::Document.new file

                    doc.elements['package/metadata'].elements.each do |element|
                        case element.name
                        when 'title'
                            @dc_title.value = element.text
                        when 'language'
                            @dc_language.value = element.text
                        when 'identifier'
                            attributes = hash_from_xml_attributes(element, true, 'dc')
                            if (attributes.has_key?('id'))
                                @dc_identifier.value = element.text
                                @dc_identifier.attributes = attributes
                            else
                                dc_item = Dc.new(element.name, element.text, attributes)
                                @dc_other.push dc_item
                            end
                        when 'meta'
                            attributes = hash_from_xml_attributes(element)
                            attributes.delete('name')
                            attributes.delete('content')
                            meta_item = Meta.new(element.attributes['name'],
                                                 element.attributes['content'], 
                                                 attributes)
                            @meta.push meta_item
                        else
                            attributes = hash_from_xml_attributes(element, true, 'dc')
                            dc_item = Dc.new(element.name, element.text, attributes)
                            @dc_other.push dc_item
                        end
                    end

                    doc.elements.each('package/manifest/item') do |item|
                        @manifest[item.attributes['id']] = ManifestItem.new(
                            item.attributes['id'],
                            item.attributes['href'],
                            item.attributes['media-type'])
                    end

                    doc.elements.each('package/spine/itemref') do |element|
                        @spine.push(SpineItemRef.new(element.attributes['idref']))
                    end

                    @toc = doc.elements['package/spine'].attributes['toc']

                    doc.elements.each('package/guide/reference') do |element|
                        @guide[element.attributes['type']] = GuideReference.new(
                            element.attributes['type'],
                            element.attributes['title'],
                            element.attributes['href'])
                    end
                end
            end

        end
    end
end
