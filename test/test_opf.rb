=begin
Test cases for the OPF classes in the Epub::Opf module.
=end
require 'FileUtils'
require 'test/unit'
require 'epub.rb'

TMP_DIR = 'test/tmp'
DATA_DIR = 'test/data'
FileUtils.mkdir_p(TMP_DIR)

class TestDc < Test::Unit::TestCase
    TITLE = 'The Constitution of the United States of America'
    AUTHOR = 'Philadelphia Convention, The'

    def test_create_two_args
        dc_item = Epub::Opf::Dc.new('title', TITLE)
        assert_equal('title', dc_item.name)
        assert_equal(TITLE, dc_item.value)
        assert_equal({}, dc_item.attributes)
    end

    def test_create_three_args
        dc_item = Epub::Opf::Dc.new('creator', AUTHOR, 
                                    {   'role'=>'aut', 
                                        'file-as' => 'The Philadelphia Convention' })

        assert_equal('creator', dc_item.name)
        assert_equal(AUTHOR, dc_item.value)
        assert_equal(2, dc_item.attributes.size, 'Expected 2 attributes')
        assert_equal('aut', dc_item.attributes['role'])
        assert_equal('The Philadelphia Convention', dc_item.attributes['file-as'])
    end

    def test_to_s_no_attributes
        dc_item = Epub::Opf::Dc.new('title', TITLE)
        assert_equal("<dc:title>#{TITLE}</dc:title>", dc_item.to_s)
    end

    def test_to_s_with_attributes
        dc_item = Epub::Opf::Dc.new('creator', AUTHOR, 
                                    {   'opf:role'=>'aut', 
                                        'opf:file-as' => 'The Philadelphia Convention' })
        assert_equal(%Q(<dc:creator opf:file-as="The Philadelphia Convention" opf:role="aut">#{AUTHOR}</dc:creator>), dc_item.to_s)
    end
end

class TestMeta < Test::Unit::TestCase
    def test_create_two_args
        meta = Epub::Opf::Meta.new('price', '12.99')
        assert_equal('price', meta.name)
        assert_equal('12.99', meta.value)
        assert_equal(meta.attributes, {})
    end

    def test_create_three_args
        meta = Epub::Opf::Meta.new('id', '42-Fnord', { 'schema' => 'bookid' })
        assert_equal('id', meta.name)
        assert_equal('42-Fnord', meta.value)
        assert_equal(1, meta.attributes.size, 'Expected 1 attribute')
        assert_equal('bookid', meta.attributes['schema'])
        assert(! meta.attributes.has_key?('name'))
        assert(! meta.attributes.has_key?('content'))
    end

    def test_to_s_no_attributes
        meta = Epub::Opf::Meta.new('price', '12.99')
        assert_equal('<meta name="price" content="12.99"/>', meta.to_s)
    end

    def test_to_s_with_attributes
        meta = Epub::Opf::Meta.new('id', '42-Fnord', { 'schema' => 'bookid' })
        assert_equal('<meta name="id" content="42-Fnord" schema="bookid"/>', meta.to_s)
    end
end

class TestManifestItem < Test::Unit::TestCase
    def test_create_html_suffix
        manifest_item = Epub::Opf::ManifestItem.new('toc', 'toc.html')
        assert_equal('toc', manifest_item.id)
        assert_equal('toc.html', manifest_item.href)
        assert_equal('application/xhtml+xml', manifest_item.media_type)
    end

    def test_create_ncx_suffix
        manifest_item = Epub::Opf::ManifestItem.new('ncx', 'toc.ncx')
        assert_equal('ncx', manifest_item.id)
        assert_equal('toc.ncx', manifest_item.href)
        assert_equal('application/x-dbtncx+xml', manifest_item.media_type)
    end

    def test_create_css_suffix
        manifest_item = Epub::Opf::ManifestItem.new('stylesheet', 'content/css/stylesheet.css')
        assert_equal('stylesheet', manifest_item.id)
        assert_equal('content/css/stylesheet.css', manifest_item.href)
        assert_equal('text/css', manifest_item.media_type)
    end

    def test_create_xml_suffix
        manifest_item = Epub::Opf::ManifestItem.new('cover', 'content/cover.xml')
        assert_equal('cover', manifest_item.id)
        assert_equal('content/cover.xml', manifest_item.href)
        assert_equal('application/xhtml+xml', manifest_item.media_type)
    end

    def test_create_gif_suffix
        manifest_item = Epub::Opf::ManifestItem.new('image1', 'images.dir/rabbit.gif')
        assert_equal('image1', manifest_item.id)
        assert_equal('images.dir/rabbit.gif', manifest_item.href)
        assert_equal('image/gif', manifest_item.media_type)
    end

    def test_create_jpg_suffix
        manifest_item = Epub::Opf::ManifestItem.new('image2', 'images.dir/bunny.jpg')
        assert_equal('image2', manifest_item.id)
        assert_equal('images.dir/bunny.jpg', manifest_item.href)
        assert_equal('image/jpeg', manifest_item.media_type)
    end

    def test_create_jpeg_suffix
        manifest_item = Epub::Opf::ManifestItem.new('image3', 'images.dir/rodent.jpeg')
        assert_equal('image3', manifest_item.id)
        assert_equal('images.dir/rodent.jpeg', manifest_item.href)
        assert_equal('image/jpeg', manifest_item.media_type)
    end

    def test_create_png_suffix
        manifest_item = Epub::Opf::ManifestItem.new('image4', 'images.dir/genus/mammal.png')
        assert_equal('image4', manifest_item.id)
        assert_equal('images.dir/genus/mammal.png', manifest_item.href)
        assert_equal('image/png', manifest_item.media_type)
    end

    def test_create_override_suffix
        manifest_item = Epub::Opf::ManifestItem.new('masq1', 'default.css', 'html')
        assert_equal('masq1', manifest_item.id)
        assert_equal('default.css', manifest_item.href)
        assert_equal('application/xhtml+xml', manifest_item.media_type)
    end

    def test_create_other_media_type
        manifest_item = Epub::Opf::ManifestItem.new('archive', 'archive.zip')
        assert_equal('archive', manifest_item.id)
        assert_equal('archive.zip', manifest_item.href)
        assert_equal('zip', manifest_item.media_type)
    end

    def test_set_media_type_gif
        manifest_item = Epub::Opf::ManifestItem.new('image4', 'images.dir/genus/mammal.png')
        manifest_item.media_type = 'gif'
        assert_equal('image4', manifest_item.id)
        assert_equal('images.dir/genus/mammal.png', manifest_item.href)
        assert_equal('image/gif', manifest_item.media_type)
    end

    def test_set_other_media_type
        manifest_item = Epub::Opf::ManifestItem.new('archive', 'archive.zip')
        manifest_item.media_type = 'application/zip'
        assert_equal('archive', manifest_item.id)
        assert_equal('archive.zip', manifest_item.href)
        assert_equal('application/zip', manifest_item.media_type)
    end

    def test_to_s_html
        manifest_item = Epub::Opf::ManifestItem.new('toc', 'toc.html')
        assert_equal('<item id="toc" href="toc.html" media-type="application/xhtml+xml"/>',
                    manifest_item.to_s)
    end

    def test_to_s_jpeg
        manifest_item = Epub::Opf::ManifestItem.new('image3', 'images.dir/rodent.jpeg')
        assert_equal('<item id="image3" href="images.dir/rodent.jpeg" media-type="image/jpeg"/>', 
                     manifest_item.to_s)
    end

    def test_to_s_other
        manifest_item = Epub::Opf::ManifestItem.new('archive', 'archive.zip', 'application/zip')
        assert_equal('<item id="archive" href="archive.zip" media-type="application/zip"/>', 
                     manifest_item.to_s)
    end
end

class TestSpineItemRef < Test::Unit::TestCase
    def test_idref_toc
        spine_item = Epub::Opf::SpineItemRef.new('toc')
        assert_equal('toc', spine_item.idref)
    end

    def test_idref_cover
        spine_item = Epub::Opf::SpineItemRef.new('cover')
        assert_equal('cover', spine_item.idref)
    end

    def test_to_s_toc
        spine_item = Epub::Opf::SpineItemRef.new('toc')
        assert_equal('<itemref idref="toc"/>', spine_item.to_s)
    end

    def test_to_s_cover
        spine_item = Epub::Opf::SpineItemRef.new('cover')
        assert_equal('<itemref idref="cover"/>', spine_item.to_s)
    end
end

class TestGuideReference < Test::Unit::TestCase
    def test_toc_reference
        guide_ref = Epub::Opf::GuideReference.new('toc', 'Table of Contents', 'toc.html')
        assert_equal('toc', guide_ref.type)
        assert_equal('Table of Contents', guide_ref.title)
        assert_equal('toc.html', guide_ref.href)
    end

    def test_text_reference
        guide_ref = Epub::Opf::GuideReference.new('text', 'Start Reading', 'content/chapter1.html')
        assert_equal('text', guide_ref.type)
        assert_equal('Start Reading', guide_ref.title)
        assert_equal('content/chapter1.html', guide_ref.href)
    end

    def test_toc_to_s
        guide_ref = Epub::Opf::GuideReference.new('toc', 'Table of Contents', 'toc.html')
        assert_equal('<reference type="toc" title="Table of Contents" href="toc.html"/>', 
                    guide_ref.to_s)
    end

    def test_text_to_s
        guide_ref = Epub::Opf::GuideReference.new('text', 'Start Reading', 'content/chapter1.html')
        assert_equal('<reference type="text" title="Start Reading" href="content/chapter1.html"/>', 
                    guide_ref.to_s)
    end
end

class TestOpfFile < Test::Unit::TestCase
    def test_create_from_scratch
        opf = Epub::Opf::OpfFile.new("#{TMP_DIR}/test-1.opf")
        assert_equal('', opf.dc_title.value)
        assert_equal('', opf.dc_language.value)
        assert_equal([], opf.meta)
        assert_equal('bookid', opf.dc_identifier.attributes['id'])
        assert_equal('', opf.dc_identifier.value)
        assert_equal([], opf.dc_other)
        assert_equal({}, opf.manifest)
        assert_equal([], opf.spine)
        assert_equal({}, opf.guide)
        assert_equal('toc.ncx', opf.toc)
    end

    def test_create_from_file_metadata
        opf = Epub::Opf::OpfFile.new("#{DATA_DIR}/velveteen_rabbit.opf")
        assert_equal('The Velveteen Rabbit or How Toys Become Real', opf.dc_title.value)
        assert_equal('en-US', opf.dc_language.value)

        assert_equal('sdid', opf.dc_identifier.attributes['id'])
        assert_equal('Spontaneous Derivation [2008.12.10-21:02:00]', opf.dc_identifier.value)

        identifiers = opf.get_dc_meta('identifier')
        assert_equal(2, identifiers.size, 'Expected 2 identifiers')
        assert_equal('sdid', identifiers[0].attributes['id'])
        assert_equal('Spontaneous Derivation [2008.12.10-21:02:00]', identifiers[0].value)
        assert_equal('isbn', identifiers[1].attributes['opf:schema'])
        assert_equal('124566820-X', identifiers[1].value)

        creators = opf.get_dc_meta('creator')
        assert_equal(2, creators.size, 'Expected 2 creators')
        assert_equal('aut', creators[0].attributes['opf:role'])
        assert_equal('Williams, Margery', creators[0].attributes['opf:file-as'])
        assert_equal('Margery Williams', creators[0].value)
        assert_equal('ill', creators[1].attributes['opf:role'])
        assert_equal('Nicholson, William', creators[1].attributes['opf:file-as'])
        assert_equal('William Nicholson', creators[1].value)

        rights = opf.get_dc_meta('rights')
        assert_equal(1, rights.size, 'Expected 1 right meta data element')
        assert_equal('Public Domain', rights[0].value)

        covers = opf.get_deprecated_meta('cover')
        assert_equal(1, covers.size, 'Expected 1 cover meta data element')
        assert_equal('cover-image', covers[0].value)
    end

    def test_create_from_file_manifest
        opf = Epub::Opf::OpfFile.new("#{DATA_DIR}/velveteen_rabbit.opf")
        assert_equal(6, opf.manifest.size, 'Expected 16 items in the manifest')

        assert_equal('toc.ncx', opf.manifest['epub-ncx'].href)
        assert_equal('application/x-dtbncx+xml', opf.manifest['epub-ncx'].media_type)

        assert_equal('toc.html', opf.manifest['toc'].href)
        assert_equal('application/xhtml+xml', opf.manifest['toc'].media_type)

        assert_equal('content/title.html', opf.manifest['titlepage'].href)
        assert_equal('application/xhtml+xml', opf.manifest['titlepage'].media_type)

        assert_equal('content/text.html', opf.manifest['text'].href)
        assert_equal('application/xhtml+xml', opf.manifest['text'].media_type)

        assert_equal('content/css/style.css', opf.manifest['stylesheet'].href)
        assert_equal('text/css', opf.manifest['stylesheet'].media_type)

        assert_equal('content/images/christmas-morning.jpg', opf.manifest['image_1'].href)
        assert_equal('image/jpeg', opf.manifest['image_1'].media_type)
    end

    def test_create_from_file_spine
        opf = Epub::Opf::OpfFile.new("#{DATA_DIR}/velveteen_rabbit.opf")
        assert_equal(4, opf.spine.size, 'Expected 4 item references in the spine')

        assert_equal('titlepage', opf.spine[0].idref)
        assert_equal('toc', opf.spine[1].idref)
        assert_equal('text', opf.spine[2].idref)
        assert_equal('titlepage', opf.spine[3].idref)

        assert_equal('epub-ncx', opf.toc)
    end

    def test_create_from_file_guide
        opf = Epub::Opf::OpfFile.new("#{DATA_DIR}/velveteen_rabbit.opf")
        assert_equal(3, opf.guide.size, 'Expected 3 guide references')

        assert_equal('Title Page', opf.guide['title-page'].title)
        assert_equal('content/title.html', opf.guide['title-page'].href)

        assert_equal('Table of Contents', opf.guide['toc'].title)
        assert_equal('toc.html', opf.guide['toc'].href)

        assert_equal('Start Reading', opf.guide['text'].title)
        assert_equal('content/text.html', opf.guide['text'].href)
    end

    def test_write_file
        input_file = "#{DATA_DIR}/velveteen_rabbit.opf"
        output_file = "#{TMP_DIR}/velveteen_rabbit.opf"
        expected_file = "#{DATA_DIR}/velveteen_rabbit-output.opf"

        opf = Epub::Opf::OpfFile.new(input_file)
        opf.file = output_file
        opf.write

        written_lines = File.open(output_file).readlines
        expected_lines = File.open(expected_file).readlines

        assert_equal(expected_lines.size, written_lines.size, "Expected #{expected_lines.size} lines")
        expected_lines.each_index do |i|
            assert_equal(expected_lines[i], written_lines[i], "Line #{i+1} differs")
        end

        File.unlink(output_file)
    end
end

__END__
