require 'RMagick'
require 'fileutils'

class ImageProcessor
  def initialize(source, target)
    @target = target
    @img    = Magick::Image.read(source).first
  end

  def constrain_width(width)
    if @img.columns == 0
      raise ProcessingError.new("The width of the image #{source} is 0")
    end

    scale_factor = width.to_f / @img.columns.to_f
    new_image = @img.resize(scale_factor)

    target_dir = File.dirname(@target)
    FileUtils.mkdir_p(target_dir)
    new_image.write(@target)
  end

  class ProcessingError < StandardError; end
end
