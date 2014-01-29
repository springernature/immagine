require 'minitest/autorun'
require_relative '../image_processor'
require 'RMagick'

describe ImageProcessor do
  test_folder = File.join(__dir__, "..", "test-data")
  source      = File.join(test_folder, "src", "images", "matz.jpg")
  target      = File.join(test_folder, "target", "images", "format_code", "matz.jpg")
  processor   = ImageProcessor.new(source, target)

  describe "#constrain_width" do
    it "resizes the width and keeps the aspec ratio" do
      processor.constrain_width(110)
      img = Magick::Image.read(target).first

      img.columns.must_equal 110
      img.rows.must_equal 164
    end
  end
end
