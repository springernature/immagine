module Immagine
  class ImageProcessorDriver
    attr_reader :image_processor, :format_processor, :quality

    def initialize(image_processor, format_processor, quality)
      @image_processor  = image_processor
      @format_processor = format_processor
      @quality          = quality
    end

    def process
      image_processor.overlay!(format_processor.overlay_color, format_processor.overlay_opacity) if format_processor.overlay?

      if format_processor.relative?
        image_processor.resize_relative_to_original!
      elsif format_processor.crop?
        image_processor.crop!(format_processor.crop_gravity, format_processor.width, format_processor.height)
      elsif format_processor.max
        image_processor.resize_by_max!(format_processor.max)
      elsif format_processor.width && format_processor.height
        image_processor.resize_and_crop!(format_processor.width, format_processor.height)
      elsif format_processor.width
        image_processor.constrain_width!(format_processor.width)
      elsif format_processor.height
        image_processor.constrain_height!(format_processor.height)
      end

      image_processor.blur!(format_processor.blur_radius, format_processor.blur_sigma) if format_processor.blur?

      img = image_processor.img

      img.strip!

      blob = img.to_blob { self.quality = quality }
      mime = img.mime_type

      [blob, mime]
    ensure
      image_processor.destroy!
    end
  end
end
