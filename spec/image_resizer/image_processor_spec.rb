require "spec_helper"

module ImageResizer
  describe ImageProcessor do
    let(:test_folder) { File.join(__dir__, "..", "..", "test-data") }
    # the original image is 220x328
    let(:source)      { File.join(test_folder, "src", "images", "matz.jpg") }
    let(:processor)   { ImageProcessor.new(source) }

    describe "#constrain_width" do
      it "resizes the width and keeps the aspect ratio" do
        img = processor.constrain_width(110)

        expect(img.columns).to eq(110)
        expect(img.rows).to eq(164)
      end

      it "should not increase the size of the image" do
        img = processor.constrain_width(230)

        expect(img.columns).to eq(220)
        expect(img.rows).to eq(328)
      end
    end

    describe "#constrain_height" do
      it "resizes the width and keeps the aspect ratio" do
        img = processor.constrain_height(164)

        expect(img.columns).to eq(110)
        expect(img.rows).to eq(164)
      end

      it "should not increase the size of the image" do
        img = processor.constrain_height(330)

        expect(img.columns).to eq(220)
        expect(img.rows).to eq(328)
      end
    end

    describe "#resize_by_max" do
      describe "when the image is portrait" do
        it "resizes by height and keeps the aspect ratio" do
          img = processor.resize_by_max(164)

          expect(img.columns).to eq(110)
          expect(img.rows).to eq(164)
        end
      end

      describe "when the image is landscape" do
        it "resizes by width and keeps the aspect ratio" do
          rotated_source = File.join(File.dirname(source), "matz-rotated.jpg")
          processor_for_rotated = ImageProcessor.new(rotated_source)

          img = processor_for_rotated.resize_by_max(164)

          expect(img.columns).to eq(164)
          expect(img.rows).to eq(110)
        end
      end
    end

    describe "#resize_and_crop" do
      describe "when the box' aspect ratio is bigger than the image's" do
        it "resizes by width and crops the height from the center" do
          img = processor.resize_and_crop(110, 100)

          expect(img.columns).to eq(110)
          expect(img.rows).to eq(100)
        end
      end

      describe "when the box' aspect ratio is smaller than the image's" do
        it "resizes by height and crops the width from the center" do
          img = processor.resize_and_crop(110, 200)

          expect(img.columns).to eq(110)
          expect(img.rows).to eq(200)
        end
      end
    end

    describe "#resize_relative_to_original" do
      describe "when the image is less than 300px wide" do
        it "does not resize the image" do
          img = processor.resize_relative_to_original

          expect(img.columns).to eq(220)
          expect(img.rows).to eq(328)
        end
      end

      describe "when the image is between 301px and 1050px wide" do
        it "resizes the image to 300px wide" do
          rotated_source = File.join(File.dirname(source), "matz-rotated.jpg") # image is 328x220
          processor_for_rotated_image = ImageProcessor.new(rotated_source)

          img = processor_for_rotated_image.resize_relative_to_original

          expect(img.columns).to eq(300)
          expect(img.rows).to eq(201)
        end
      end

      describe "when the image is over 1050px wide" do
        it "resizes a landscape image to 703px wide" do
          big_source = File.join(File.dirname(source), "kitten.jpg") # image is 3072x2304
          processor_for_big_image = ImageProcessor.new(big_source)

          img = processor_for_big_image.resize_relative_to_original

          expect(img.columns).to eq(703)
          expect(img.rows).to eq(527)
        end

        it "resizes a portrait image to 703px high" do
          big_source = File.join(File.dirname(source), "kitten-rotated.jpg") # image is 2304x3072
          processor_for_big_image = ImageProcessor.new(big_source)

          img = processor_for_big_image.resize_relative_to_original

          expect(img.columns).to eq(527)
          expect(img.rows).to eq(703)
        end
      end
    end

    describe "Properties of produces images" do
      describe "when the format is JPEG" do
        it "uses JPEGCompression" do
          img = processor.constrain_width(100)

          expect(img.compression).to eq(Magick::JPEGCompression)
        end
      end

      it "uses baseline encoding for small images" do
        img = processor.resize_by_max(20)

        expect(img.interlace).to eq(Magick::NoInterlace)
      end

      it "uses progressive encoding for bigger images" do
        img = processor.resize_by_max(600)

        expect(img.interlace).to eq(Magick::PlaneInterlace)
      end
    end
  end
end
