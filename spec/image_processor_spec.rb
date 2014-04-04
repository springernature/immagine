require "spec_helper"

module ImageResizer
  describe ImageProcessor do
    let(:test_folder) { File.join(__dir__, "..", "test-data") }
    # the original image is 220x328
    let(:source)      { File.join(test_folder, "src", "images", "matz.jpg") }
    let(:target)      { File.join(test_folder, "target", "images", "format_code", "matz.jpg") }
    let(:processor)   { ImageProcessor.new(source, target) }

    describe "#constrain_width" do
      it "resizes the width and keeps the aspect ratio" do
        processor.constrain_width(110)
        img = image(target)

        expect(img.columns).to eq(110)
        expect(img.rows).to eq(164)
      end
    end

    describe "#constrain_height" do
      it "resizes the width and keeps the aspect ratio" do
        processor.constrain_height(164)
        img = image(target)

        expect(img.columns).to eq(110)
        expect(img.rows).to eq(164)
      end
    end

    describe "#resize_by_max" do
      describe "when the image is portrait" do
        it "resizes by height and keeps the aspect ratio" do
          processor.resize_by_max(164)
          img = image(target)

          expect(img.columns).to eq(110)
          expect(img.rows).to eq(164)
        end
      end

      describe "when the image is landscape" do
        it "resizes by width and keeps the aspect ratio" do
          rotated_source = File.join(File.dirname(source), "matz-rotated.jpg")
          processor_for_rotated = ImageProcessor.new(rotated_source, target)

          processor_for_rotated.resize_by_max(164)
          img = image(target)

          expect(img.columns).to eq(164)
          expect(img.rows).to eq(110)
        end
      end
    end

    describe "#resize_and_crop" do
      describe "when the box' aspect ratio is bigger than the image's" do
        it "resizes by width and crops the height from the center" do
          processor.resize_and_crop(110, 100)
          img = image(target)

          expect(img.columns).to eq(110)
          expect(img.rows).to eq(100)
        end
      end

      describe "when the box' aspect ratio is smaller than the image's" do
        it "resizes by height and crops the width from the center" do
          processor.resize_and_crop(110, 200)
          img = image(target)

          expect(img.columns).to eq(110)
          expect(img.rows).to eq(200)
        end
      end
    end

    describe "Properties of produces images" do
      describe "when the format is JPEG" do
        it "uses JPEGCompression" do
          processor.constrain_width(100)
          img = image(target)

          expect(img.compression).to eq(Magick::JPEGCompression)
        end
      end

      it "uses baseline encoding for small images" do
        processor.resize_by_max(20)
        img = image(target)

        expect(img.interlace).to eq(Magick::NoInterlace)
      end

      it "uses progressive encoding for bigger images" do
        processor.resize_by_max(600)
        img = image(target)

        expect(img.interlace).to eq(Magick::JPEGInterlace)
      end
    end

    def image(file)
      Magick::Image.read(file).first
    end
  end
end
