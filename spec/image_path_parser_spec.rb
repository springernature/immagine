require 'minitest/autorun'
require_relative '../image_path_parser'

describe ImagePathParser do
  describe "#parse" do
    it "splits an image path into a directory, format code and basename" do
      dir, format_code, basename = ImagePathParser.new.parse("/foo/bar/w300/baz.jpg")

      dir.must_equal "/foo/bar"
      format_code.must_equal "w300"
      basename.must_equal "baz.jpg"
    end

    describe "when an invalid format is given" do
      it "raises a ImageResizer::ParseError" do
        proc {
          ImagePathParser.new.parse("invalid string")
        }.must_raise ImagePathParser::ParseError
      end
    end

    describe "when .. is in the path" do
      it "raises a ImageResizer::ParseError" do
        proc {
          ImagePathParser.new.parse("/foo/bar/../../w300/baz.jpg")
        }.must_raise ImagePathParser::ParseError
      end
    end
  end
end
