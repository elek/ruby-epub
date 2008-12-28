=begin
Test cases for the OPF classes in the Epub::Opf module.
=end
require 'FileUtils'
require 'test/unit'
require 'epub.rb'

TMP_DIR = 'test/tmp'
DATA_DIR = 'test/data'
FileUtils.mkdir_p(TMP_DIR)

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
    def test_single_np
        point = Epub::Ncx::NavigationPoint.new('title', '1', 'Title', 'content/title.html')
        assert_equal('title', point.id)
        assert_equal('1', point.play_order)
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
        assert_equal('3', parent.play_order)
        assert_equal('Article I. [The Legislative Branch]', parent.label)
        assert_equal('content/article-1.html', parent.content)
        assert_equal(1, parent.points.size, 'Expected 1 child point')

        assert_equal('article-1-section-1', child_1.id)
        assert_equal('4', child_1.play_order)
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
        assert_equal('14', parent.play_order)
        assert_equal('Article II. [The Presidency]', parent.label)
        assert_equal('content/article-2.html', parent.content)
        assert_equal(2, parent.points.size, 'Expected 2 child point')

        assert_equal('article-2-section-1', child_1.id)
        assert_equal('15', child_1.play_order)
        assert_equal('Section 1. [Election, Installment, Removal]', child_1.label)
        assert_equal('content/article-2.html#section1', child_1.content)
        assert_equal([], child_1.points)

        assert_equal('article-2-section-2', child_2.id)
        assert_equal('16', child_2.play_order)
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
        assert_equal('14', parent.play_order)
        assert_equal('Article II. [The Presidency]', parent.label)
        assert_equal('content/article-2.html', parent.content)
        assert_equal(1, parent.points.size, 'Expected 1 child point')

        assert_equal('article-2-section-1', child_1.id)
        assert_equal('15', child_1.play_order)
        assert_equal('Section 1. [Election, Installment, Removal]', child_1.label)
        assert_equal('content/article-2.html#section1', child_1.content)
        assert_equal(1, child_1.points.size, 'Expected 1 child point')

        assert_equal('article-2-section-2', child_2.id)
        assert_equal('16', child_2.play_order)
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
    end

    def test_create_from_file
        ncx = Epub::Ncx::NcxFile.new("#{DATA_DIR}/us-constitution.ncx")

        assert_equal(4, ncx.metadata.size, 'Expected 4 metadata elements')
        assert_equal('Spontaneous Derivation [Tue Dec 23 20:40:31 -0800 2008]', 
                     ncx.metadata['dtb:uid'].content)
        assert_equal('1', ncx.metadata['dtb:depth'].content)
        assert_equal('0', ncx.metadata['dtb:totalPageCount'].content)
        assert_equal('0', ncx.metadata['dtb:maxPageNumber'].content)

        assert_equal('The United States Constitution', ncx.title)

        assert_equal(11, ncx.map.size, 'Expected 11 top-level navigation points')

        assert_equal('Title', ncx.map[0].label)
        assert_equal(0, ncx.map[0].points.size)
        assert_equal('title', ncx.map[0].id)
        assert_equal('1', ncx.map[0].play_order)
        assert_equal('content/title.html', ncx.map[0].content)

        assert_equal('Preamble', ncx.map[1].label)
        assert_equal(0, ncx.map[1].points.size)
        assert_equal('preamble', ncx.map[1].id)
        assert_equal('2', ncx.map[1].play_order)
        assert_equal('content/preamble.html', ncx.map[1].content)

        assert_equal('Article I. [The Legislative Branch]', ncx.map[2].label)
        assert_equal(10, ncx.map[2].points.size)
        assert_equal('article-1', ncx.map[2].id)
        assert_equal('3', ncx.map[2].play_order)
        assert_equal('content/article-1.html', ncx.map[2].content)

        assert_equal('Section 1. [Legislative Power Vested]', ncx.map[2].points[0].label)
        assert_equal(0, ncx.map[2].points[0].points.size)
        assert_equal('article-1-section-1', ncx.map[2].points[0].id)
        assert_equal('4', ncx.map[2].points[0].play_order)
        assert_equal('content/article-1.html#section1', ncx.map[2].points[0].content)

        assert_equal('Section 2. [House of Representatives]', ncx.map[2].points[1].label)
        assert_equal(0, ncx.map[2].points[0].points.size)
        assert_equal('article-1-section-2', ncx.map[2].points[1].id)
        assert_equal('5', ncx.map[2].points[1].play_order)
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

        written_lines = File.open(output_file).readlines
        expected_lines = File.open(expected_file).readlines

        assert_equal(expected_lines.size, written_lines.size, "Expected #{expected_lines.size} lines")
        expected_lines.each_index do |i|
            assert_equal(expected_lines[i], written_lines[i], "Line #{i+1} differs")
        end

        File.unlink(output_file)
    end
end
