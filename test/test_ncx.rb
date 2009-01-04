=begin
Test cases for the OPF classes in the Epub::Opf module.
=end
require 'FileUtils'

require 'test_unit_additions.rb'
require 'test/unit'
require 'epub.rb'

class TestMetaData < Test::Unit::TestCase
    def test_meta_uid
        meta = Epub::Ncx::MetaData.new('dtb:uid', 'Spontaneous Derivation [Tue Dec 23 20:40:31 -0800 2008]')
        assert_equal('dtb:uid', meta.name)
        assert_equal('Spontaneous Derivation [Tue Dec 23 20:40:31 -0800 2008]', meta.content)
    end

    def test_meta_depth
        meta = Epub::Ncx::MetaData.new('dtb:depth', '1')
        assert_equal('dtb:depth', meta.name)
        assert_equal('1', meta.content)
    end

    def test_meta_uid_to_s
        meta = Epub::Ncx::MetaData.new('dtb:uid', 'Spontaneous Derivation [Tue Dec 23 20:40:31 -0800 2008]')
        assert_equal('<meta name="dtb:uid" content="Spontaneous Derivation [Tue Dec 23 20:40:31 -0800 2008]"/>', meta.to_s)
    end

    def test_meta_depth_to_s
        meta = Epub::Ncx::MetaData.new('dtb:depth', '1')
        assert_equal('<meta name="dtb:depth" content="1"/>', meta.to_s)
    end
end

class TestNavigationPoint < Test::Unit::TestCase
    def test_single_np_string_play_order
        point = Epub::Ncx::NavigationPoint.new('title', '1', 'Title', 'content/title.html')
        assert_equal('title', point.id)
        assert_equal(1, point.play_order)
        assert_equal('Title', point.label)
        assert_equal('content/title.html', point.content)
        assert_equal([], point.points)
    end

    def test_single_np_number_play_order
        point = Epub::Ncx::NavigationPoint.new('title', 1, 'Title', 'content/title.html')
        assert_equal('title', point.id)
        assert_equal(1, point.play_order)
        assert_equal('Title', point.label)
        assert_equal('content/title.html', point.content)
        assert_equal([], point.points)
    end

    def test_single_np_to_s
        point = Epub::Ncx::NavigationPoint.new('title', '1', 'Title', 'content/title.html')
        s = <<-END
<navPoint id="title" playOrder="1">
  <navLabel>
    <text>Title</text>
  </navLabel>
  <content src="content/title.html"/>
</navPoint>
        END
        assert_equal(s, point.to_s)
    end

    def test_single_nested_np
        parent = Epub::Ncx::NavigationPoint.new('article-1', '3', 
                                                'Article I. [The Legislative Branch]', 
                                                'content/article-1.html')
        child_1 = Epub::Ncx::NavigationPoint.new('article-1-section-1', '4', 
                                                 'Section 1. [Legislative Power Vested]', 
                                                 'content/article-1.html#section1')
        parent.points.push child_1

        assert_equal('article-1', parent.id)
        assert_equal(3, parent.play_order)
        assert_equal('Article I. [The Legislative Branch]', parent.label)
        assert_equal('content/article-1.html', parent.content)
        assert_equal(1, parent.points.size, 'Expected 1 child point')

        assert_equal('article-1-section-1', child_1.id)
        assert_equal(4, child_1.play_order)
        assert_equal('Section 1. [Legislative Power Vested]', child_1.label)
        assert_equal('content/article-1.html#section1', child_1.content)
        assert_equal([], child_1.points)
    end

    def test_single_nested_np_to_s
        parent = Epub::Ncx::NavigationPoint.new('article-1', '3', 
                                                'Article I. [The Legislative Branch]', 
                                                'content/article-1.html')
        child_1 = Epub::Ncx::NavigationPoint.new('article-1-section-1', '4', 
                                                 'Section 1. [Legislative Power Vested]', 
                                                 'content/article-1.html#section1')
        parent.points.push child_1

        s = <<-END
<navPoint id="article-1" playOrder="3">
  <navLabel>
    <text>Article I. [The Legislative Branch]</text>
  </navLabel>
  <content src="content/article-1.html"/>
<navPoint id="article-1-section-1" playOrder="4">
  <navLabel>
    <text>Section 1. [Legislative Power Vested]</text>
  </navLabel>
  <content src="content/article-1.html#section1"/>
</navPoint>
</navPoint>
        END

        assert_equal(s, parent.to_s)
    end

    def test_multiple_nested_np_depth_1
        parent = Epub::Ncx::NavigationPoint.new('article-2', '14', 
                                                'Article II. [The Presidency]', 
                                                'content/article-2.html')

        child_1 = Epub::Ncx::NavigationPoint.new('article-2-section-1', '15', 
                                                 'Section 1. [Election, Installment, Removal]', 
                                                 'content/article-2.html#section1')
        parent.points.push child_1
        child_2 = Epub::Ncx::NavigationPoint.new('article-2-section-2', '16', 
                                                 'Section 2. [Presidential Power]', 
                                                 'content/article-2.html#section2')
        parent.points.push child_2

        assert_equal('article-2', parent.id)
        assert_equal(14, parent.play_order)
        assert_equal('Article II. [The Presidency]', parent.label)
        assert_equal('content/article-2.html', parent.content)
        assert_equal(2, parent.points.size, 'Expected 2 child point')

        assert_equal('article-2-section-1', child_1.id)
        assert_equal(15, child_1.play_order)
        assert_equal('Section 1. [Election, Installment, Removal]', child_1.label)
        assert_equal('content/article-2.html#section1', child_1.content)
        assert_equal([], child_1.points)

        assert_equal('article-2-section-2', child_2.id)
        assert_equal(16, child_2.play_order)
        assert_equal('Section 2. [Presidential Power]', child_2.label)
        assert_equal('content/article-2.html#section2', child_2.content)
        assert_equal([], child_2.points)
    end

    def test_multiple_nested_np_depth_1_to_s
        parent = Epub::Ncx::NavigationPoint.new('article-2', '14', 
                                                'Article II. [The Presidency]', 
                                                'content/article-2.html')

        child_1 = Epub::Ncx::NavigationPoint.new('article-2-section-1', '15', 
                                                 'Section 1. [Election, Installment, Removal]', 
                                                 'content/article-2.html#section1')
        parent.points.push child_1
        child_2 = Epub::Ncx::NavigationPoint.new('article-2-section-2', '16', 
                                                 'Section 2. [Presidential Power]', 
                                                 'content/article-2.html#section2')
        parent.points.push child_2

        s = <<-END
<navPoint id="article-2" playOrder="14">
  <navLabel>
    <text>Article II. [The Presidency]</text>
  </navLabel>
  <content src="content/article-2.html"/>
<navPoint id="article-2-section-1" playOrder="15">
  <navLabel>
    <text>Section 1. [Election, Installment, Removal]</text>
  </navLabel>
  <content src="content/article-2.html#section1"/>
</navPoint>
<navPoint id="article-2-section-2" playOrder="16">
  <navLabel>
    <text>Section 2. [Presidential Power]</text>
  </navLabel>
  <content src="content/article-2.html#section2"/>
</navPoint>
</navPoint>
        END
        assert_equal(s, parent.to_s)
    end

    def test_multiple_nested_np_depth_2
        parent = Epub::Ncx::NavigationPoint.new('article-2', '14', 
                                                'Article II. [The Presidency]', 
                                                'content/article-2.html')

        child_1 = Epub::Ncx::NavigationPoint.new('article-2-section-1', '15', 
                                                 'Section 1. [Election, Installment, Removal]', 
                                                 'content/article-2.html#section1')
        parent.points.push child_1
        child_2 = Epub::Ncx::NavigationPoint.new('article-2-section-2', '16', 
                                                 'Section 2. [Presidential Power]', 
                                                 'content/article-2.html#section2')
        child_1.points.push child_2

        assert_equal('article-2', parent.id)
        assert_equal(14, parent.play_order)
        assert_equal('Article II. [The Presidency]', parent.label)
        assert_equal('content/article-2.html', parent.content)
        assert_equal(1, parent.points.size, 'Expected 1 child point')

        assert_equal('article-2-section-1', child_1.id)
        assert_equal(15, child_1.play_order)
        assert_equal('Section 1. [Election, Installment, Removal]', child_1.label)
        assert_equal('content/article-2.html#section1', child_1.content)
        assert_equal(1, child_1.points.size, 'Expected 1 child point')

        assert_equal('article-2-section-2', child_2.id)
        assert_equal(16, child_2.play_order)
        assert_equal('Section 2. [Presidential Power]', child_2.label)
        assert_equal('content/article-2.html#section2', child_2.content)
        assert_equal([], child_2.points)
    end

    def test_multiple_nested_np_depth_2_to_s
        parent = Epub::Ncx::NavigationPoint.new('article-2', '14', 
                                                'Article II. [The Presidency]', 
                                                'content/article-2.html')

        child_1 = Epub::Ncx::NavigationPoint.new('article-2-section-1', '15', 
                                                 'Section 1. [Election, Installment, Removal]', 
                                                 'content/article-2.html#section1')
        parent.points.push child_1
        child_2 = Epub::Ncx::NavigationPoint.new('article-2-section-2', '16', 
                                                 'Section 2. [Presidential Power]', 
                                                 'content/article-2.html#section2')
        child_1.points.push child_2

        s = <<-END
<navPoint id="article-2" playOrder="14">
  <navLabel>
    <text>Article II. [The Presidency]</text>
  </navLabel>
  <content src="content/article-2.html"/>
<navPoint id="article-2-section-1" playOrder="15">
  <navLabel>
    <text>Section 1. [Election, Installment, Removal]</text>
  </navLabel>
  <content src="content/article-2.html#section1"/>
<navPoint id="article-2-section-2" playOrder="16">
  <navLabel>
    <text>Section 2. [Presidential Power]</text>
  </navLabel>
  <content src="content/article-2.html#section2"/>
</navPoint>
</navPoint>
</navPoint>
        END
    end
end

class TestNcxFile < Test::Unit::TestCase
    def test_create_from_scratch
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")
        assert_equal({}, ncx.metadata)
        assert_equal('', ncx.title)
        assert_equal([], ncx.map)
        assert_equal('', ncx.identifier)
    end

    def test_add_metadata
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")
        ncx.add_metadata('dtb:depth', '1')
        assert_equal('1', ncx.metadata['dtb:depth'].content)
    end

    def test_delete_metadata
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")
        ncx.add_metadata('dtb:depth', '1')
        ncx.delete_metadata('dtb:depth')
        assert_nil(ncx.metadata['dtb:depth'])
    end

    def test_set_identifier
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")
        ncx.identifier = '42'
        assert_equal('42', ncx.identifier)
    end

    def test_create_from_file
        ncx = Epub::Ncx::NcxFile.new("#{DATA_DIR}/us-constitution.ncx")

        assert_equal('Spontaneous Derivation [Tue Dec 23 20:40:31 -0800 2008]', 
                     ncx.identifier)

        assert_equal(3, ncx.metadata.size, 'Expected 3 non-uid metadata elements')
        assert_equal('1', ncx.metadata['dtb:depth'].content)
        assert_equal('0', ncx.metadata['dtb:totalPageCount'].content)
        assert_equal('0', ncx.metadata['dtb:maxPageNumber'].content)

        assert_equal('The United States Constitution', ncx.title)

        assert_equal(11, ncx.map.size, 'Expected 11 top-level navigation points')

        assert_equal('Title', ncx.map[0].label)
        assert_equal(0, ncx.map[0].points.size)
        assert_equal('title', ncx.map[0].id)
        assert_equal(1, ncx.map[0].play_order)
        assert_equal('content/title.html', ncx.map[0].content)

        assert_equal('Preamble', ncx.map[1].label)
        assert_equal(0, ncx.map[1].points.size)
        assert_equal('preamble', ncx.map[1].id)
        assert_equal(2, ncx.map[1].play_order)
        assert_equal('content/preamble.html', ncx.map[1].content)

        assert_equal('Article I. [The Legislative Branch]', ncx.map[2].label)
        assert_equal(10, ncx.map[2].points.size)
        assert_equal('article-1', ncx.map[2].id)
        assert_equal(3, ncx.map[2].play_order)
        assert_equal('content/article-1.html', ncx.map[2].content)

        assert_equal('Section 1. [Legislative Power Vested]', ncx.map[2].points[0].label)
        assert_equal(0, ncx.map[2].points[0].points.size)
        assert_equal('article-1-section-1', ncx.map[2].points[0].id)
        assert_equal(4, ncx.map[2].points[0].play_order)
        assert_equal('content/article-1.html#section1', ncx.map[2].points[0].content)

        assert_equal('Section 2. [House of Representatives]', ncx.map[2].points[1].label)
        assert_equal(0, ncx.map[2].points[0].points.size)
        assert_equal('article-1-section-2', ncx.map[2].points[1].id)
        assert_equal(5, ncx.map[2].points[1].play_order)
        assert_equal('content/article-1.html#section2', ncx.map[2].points[1].content)

        assert_equal(4, ncx.map[3].points.size)
        assert_equal(3, ncx.map[4].points.size)
        assert_equal(4, ncx.map[5].points.size)
        assert_equal(0, ncx.map[6].points.size)
        assert_equal(0, ncx.map[7].points.size)
        assert_equal(0, ncx.map[8].points.size)
        assert_equal(0, ncx.map[9].points.size)
        assert_equal(27, ncx.map[10].points.size)
    end

    def test_write
        input_file = "#{DATA_DIR}/us-constitution.ncx"
        output_file = "#{TMP_DIR}/us-constitution.ncx"
        expected_file = "#{DATA_DIR}/us-constitution-output.ncx"

        ncx = Epub::Ncx::NcxFile.new(input_file)
        ncx.file = output_file
        ncx.write

        assert_files_same(expected_file, output_file)
        File.unlink(output_file)
    end

    def test_add_navigation_point_first
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        new_np = ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        assert_equal(1, ncx.map.size, 'Expected 1 item in the map!')

        assert_not_nil(new_np, 'Did not get a navigation point')
        assert_equal('title', new_np.id)
        assert_equal('Title of Work', new_np.label)
        assert_equal('content/title.html', new_np.content)
        assert_equal(1, new_np.play_order)

        np_from_map = ncx.map[0]
        assert_not_nil(np_from_map, 'Did not find navigation point in map')
        assert_equal('title', np_from_map.id)
        assert_equal('Title of Work', np_from_map.label)
        assert_equal('content/title.html', np_from_map.content)
        assert_equal(1, np_from_map.play_order)
    end

    def test_add_navigation_point_second
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        np1 = ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        np2 = ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')

        assert_equal(2, ncx.map.size, 'Expected 2 items in the map!')

        assert_not_nil(np2, 'Did not get a navigation point')
        assert_equal('chapter1', np2.id)
        assert_equal('Chapter 1', np2.label)
        assert_equal('content/chapter-1.html', np2.content)
        assert_equal(2, np2.play_order)

        first_np_from_map = ncx.map[0]
        assert_not_nil(first_np_from_map, 'Did not find first navigation point in map')
        assert_equal('title', first_np_from_map.id)
        assert_equal('Title of Work', first_np_from_map.label)
        assert_equal('content/title.html', first_np_from_map.content)
        assert_equal(1, first_np_from_map.play_order)

        second_np_from_map = ncx.map[1]
        assert_not_nil(second_np_from_map, 'Did not find second navigation point in map')
        assert_equal('chapter1', second_np_from_map.id)
        assert_equal('Chapter 1', second_np_from_map.label)
        assert_equal('content/chapter-1.html', second_np_from_map.content)
        assert_equal(2, second_np_from_map.play_order)
    end

    def test_insert_navigation_point_middle
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')
        np_middle = ncx.insert_navigation_point('preface', 'Preface', 'content/preface.html', 2)
        assert_equal(3, ncx.map.size, 'Expected 3 items in map')

        assert_not_nil(np_middle, 'Did not get a navigation point')
        assert_equal('preface', np_middle.id)
        assert_equal('Preface', np_middle.label)
        assert_equal('content/preface.html', np_middle.content)
        assert_equal(2, np_middle.play_order)

        np_middle_from_map = ncx.map[1]
        assert_not_nil(np_middle_from_map, 'Did not get middle navigation point from map')
        assert_equal('preface', np_middle_from_map.id)
        assert_equal('Preface', np_middle_from_map.label)
        assert_equal('content/preface.html', np_middle_from_map.content)
        assert_equal(2, np_middle_from_map.play_order)

        np_start_from_map = ncx.map[0]
        assert_not_nil(np_start_from_map, 'Did not get start navigation point from map')
        assert_equal('title', np_start_from_map.id)
        assert_equal('Title of Work', np_start_from_map.label)
        assert_equal('content/title.html', np_start_from_map.content)
        assert_equal(1, np_start_from_map.play_order)

        np_end_from_map = ncx.map[2]
        assert_not_nil(np_end_from_map, 'Did not get end navigation point from map')
        assert_equal('chapter1', np_end_from_map.id)
        assert_equal('Chapter 1', np_end_from_map.label)
        assert_equal('content/chapter-1.html', np_end_from_map.content)
        assert_equal(3, np_end_from_map.play_order)
    end

    def test_insert_navigation_point_begin
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')
        np_cover = ncx.insert_navigation_point('cover', 'Cover', 'content/cover.xml', 1)
        assert_equal(3, ncx.map.size, 'Expected 3 items in map')

        assert_not_nil(np_cover, 'Did not get a navigation point')
        assert_equal('cover', np_cover.id)
        assert_equal('Cover', np_cover.label)
        assert_equal('content/cover.xml', np_cover.content)
        assert_equal(1, np_cover.play_order)

        np_cover_from_map = ncx.map[0]
        assert_not_nil(np_cover_from_map, 'Did not get cover navigation point from map')
        assert_equal('cover', np_cover_from_map.id)
        assert_equal('Cover', np_cover_from_map.label)
        assert_equal('content/cover.xml', np_cover_from_map.content)
        assert_equal(1, np_cover_from_map.play_order)

        np_start_from_map = ncx.map[1]
        assert_not_nil(np_start_from_map, 'Did not get start navigation point from map')
        assert_equal('title', np_start_from_map.id)
        assert_equal('Title of Work', np_start_from_map.label)
        assert_equal('content/title.html', np_start_from_map.content)
        assert_equal(2, np_start_from_map.play_order)

        np_end_from_map = ncx.map[2]
        assert_not_nil(np_end_from_map, 'Did not get end navigation point from map')
        assert_equal('chapter1', np_end_from_map.id)
        assert_equal('Chapter 1', np_end_from_map.label)
        assert_equal('content/chapter-1.html', np_end_from_map.content)
        assert_equal(3, np_end_from_map.play_order)
    end

    def test_insert_navigation_point_end
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')
        np_chap2 = ncx.insert_navigation_point('chapter2', 'Chapter 2', 'content/chapter-2.html', 3)
        assert_equal(3, ncx.map.size, 'Expected 3 items in map')

        assert_not_nil(np_chap2, 'Did not get a navigation point')
        assert_equal('chapter2', np_chap2.id)
        assert_equal('Chapter 2', np_chap2.label)
        assert_equal('content/chapter-2.html', np_chap2.content)
        assert_equal(3, np_chap2.play_order)

        np_chap2_from_map = ncx.map[2]
        assert_not_nil(np_chap2_from_map, 'Did not get chap2 navigation point from map')
        assert_equal('chapter2', np_chap2_from_map.id)
        assert_equal('Chapter 2', np_chap2_from_map.label)
        assert_equal('content/chapter-2.html', np_chap2_from_map.content)
        assert_equal(3, np_chap2_from_map.play_order)

        np_start_from_map = ncx.map[0]
        assert_not_nil(np_start_from_map, 'Did not get start navigation point from map')
        assert_equal('title', np_start_from_map.id)
        assert_equal('Title of Work', np_start_from_map.label)
        assert_equal('content/title.html', np_start_from_map.content)
        assert_equal(1, np_start_from_map.play_order)

        np_end_from_map = ncx.map[1]
        assert_not_nil(np_end_from_map, 'Did not get end navigation point from map')
        assert_equal('chapter1', np_end_from_map.id)
        assert_equal('Chapter 1', np_end_from_map.label)
        assert_equal('content/chapter-1.html', np_end_from_map.content)
        assert_equal(2, np_end_from_map.play_order)
    end

    def test_insert_navigation_point_too_big
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')

        begin
            ncx.insert_navigation_point('chapter2', 'Chapter 2', 'content/chapter-2.html', 4)
        rescue => ex
            assert_equal('Play order 4 is greater than the new map size of 3!', ex.message)
        else
            flunk 'Expected exception'
        end
    end

    def test_insert_navigation_point_zero_play_order
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')

        begin
            ncx.insert_navigation_point('chapter2', 'Chapter 2', 'content/chapter-2.html', 0)
        rescue => ex
            assert_equal('Play order 0 is 0 or less!', ex.message)
        else
            flunk 'Expected exception'
        end
    end

    def test_insert_navigation_point_negative_play_order
        ncx = Epub::Ncx::NcxFile.new("#{TMP_DIR}/test.ncx")

        ncx.add_navigation_point('title', 'Title of Work', 'content/title.html')
        ncx.add_navigation_point('chapter1', 'Chapter 1', 'content/chapter-1.html')

        begin
            ncx.insert_navigation_point('chapter2', 'Chapter 2', 'content/chapter-2.html', -1232124)
        rescue => ex
            assert_equal('Play order -1232124 is 0 or less!', ex.message)
        else
            flunk 'Expected exception'
        end
    end
end
