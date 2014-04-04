require "spec_helper"

module ImageResizer
  describe ImagePathParser do
    describe "#parse" do
      it "splits an image path into a directory, format code and basename" do
        dir, format_code, basename = ImagePathParser.new.parse("/foo/bar/w300/baz.jpg")

        expect(dir).to eq("/foo/bar")
        expect(format_code).to eq("w300")
        expect(basename).to eq("baz.jpg")
      end

      describe "when an invalid format is given" do
        it "raises a ImageResizer::ParseError" do
          expect do
            ImagePathParser.new.parse("invalid string")
          end.to raise_error(ImagePathParser::ParseError)
        end
      end

      describe "when .. is in the path" do
        it "raises a ImageResizer::ParseError" do
          expect do
            ImagePathParser.new.parse("/foo/bar/../../w300/baz.jpg")
          end.to raise_error(ImagePathParser::ParseError)
        end
      end
    end
  end
end
