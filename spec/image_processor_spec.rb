require 'minitest/autorun'
require_relative '../image_processor'
require 'RMagick'

describe ImageProcessor do
  test_folder = File.join(__dir__, "..", "test-data")
  # the original image is 220x328
  source      = File.join(test_folder, "src", "images", "matz.jpg")
  target      = File.join(test_folder, "target", "images", "format_code", "matz.jpg")
  processor   = ImageProcessor.new(source, target)

  describe "#constrain_width" do
    it "resizes the width and keeps the aspect ratio" do
      processor.constrain_width(110)
      img = image(target)

      img.columns.must_equal 110
      img.rows.must_equal 164
    end
  end

  describe "#constrain_height" do
    it "resizes the width and keeps the aspect ratio" do
      processor.constrain_height(164)
      img = image(target)

      img.columns.must_equal 110
      img.rows.must_equal 164
    end
  end

  describe "#resize_by_max" do
    describe "when the image is portrait" do
      it "resizes by height and keeps the aspect ratio" do
        processor.resize_by_max(164)
        img = image(target)

        img.columns.must_equal 110
        img.rows.must_equal 164
      end
    end

    describe "when the image is landscape" do
      it "resizes by width and keeps the aspect ratio" do
        rotated_source = File.join(File.dirname(source), "matz-rotated.jpg")
        processor_for_rotated = ImageProcessor.new(rotated_source, target)

        processor_for_rotated.resize_by_max(164)
        img = image(target)

        img.columns.must_equal 164
        img.rows.must_equal 110
      end
    end
  end

  describe "#resize_and_crop" do
    describe "when the box' aspect ratio is bigger than the image's" do
      it "resizes by width and crops the height from the center" do
        processor.resize_and_crop(110, 100)
        img = image(target)

        img.columns.must_equal 110
        img.rows.must_equal 100
      end
    end

    describe "when the box' aspect ratio is smaller than the image's" do
      it "resizes by height and crops the width from the center" do
        processor.resize_and_crop(110, 200)
        img = image(target)

        img.columns.must_equal 110
        img.rows.must_equal 200
      end
    end
  end

  def image(file)
    Magick::Image.read(file).first
  end
end
