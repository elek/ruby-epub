require 'test/unit'
require 'epub.rb'

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
                                    {   'opf:role'=>'aut', 
                                        'opf:file-as' => 'The Philadelphia Convention' })

        assert_equal('creator', dc_item.name)
        assert_equal(AUTHOR, dc_item.value)
        assert_equal(2, dc_item.attributes.size)
        assert_equal('aut', dc_item.attributes['opf:role'])
        assert_equal('The Philadelphia Convention', dc_item.attributes['opf:file-as'])
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
        assert_equal(1, meta.attributes.size)
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
