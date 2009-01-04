require 'test/unit/assertions'
require 'FileUtils'

unless defined? TMP_DIR
    TMP_DIR = 'test/tmp'
    FileUtils.mkdir_p(TMP_DIR)
end
unless defined? DATA_DIR
    DATA_DIR = 'test/data'
end

module Test::Unit::Assertions
    def assert_files_same(expected_file, output_file)
        output_lines = File.open(output_file).readlines
        expected_lines = File.open(expected_file).readlines

        assert_equal(expected_lines.size, output_lines.size, "Expected #{expected_lines.size} lines")
        expected_lines.each_index do |i|
            assert_equal(expected_lines[i], output_lines[i], "Line #{i+1} differs")
        end
    end
end
