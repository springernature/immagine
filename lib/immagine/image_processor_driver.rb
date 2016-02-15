module Immagine
  class ImageProcessorDriver
    attr_reader :image_processor, :format_processor, :conversion_format, :quality

    def initialize(image_processor, format_processor, conversion_format, quality)
      @image_processor   = image_processor
      @format_processor  = format_processor
      @conversion_format = conversion_format
      @quality           = quality
    end

    def process
      # OVERLAY
      image_processor.overlay!(format_processor.overlay_color, format_processor.overlay_opacity) if format_processor.overlay?

      # RESIZE
      if format_processor.relative?
        image_processor.resize_relative_to_original!
      elsif format_processor.max
        image_processor.resize_by_max!(format_processor.max)
      elsif format_processor.width && format_processor.height
        image_processor.resize_and_crop!(format_processor.width, format_processor.height)
      elsif format_processor.width
        image_processor.constrain_width!(format_processor.width)
      elsif format_processor.height
        image_processor.constrain_height!(format_processor.height)
      end

      # CROP
      if format_processor.crop?
        if format_processor.crop_resize_ratio
          ratio = format_processor.crop_resize_ratio
          cols  = (image_processor.img.columns * ratio).to_i.round
          rows  = (image_processor.img.rows * ratio).to_i.round

          image_processor.resize_and_crop!(cols, rows)
        end

        image_processor.crop!(format_processor.crop_gravity, format_processor.crop_width, format_processor.crop_height)
      end

      # BLUR
      image_processor.blur!(format_processor.blur_radius, format_processor.blur_sigma) if format_processor.blur?

      # CONVERT
      if conversion_format
        image_processor.convert_format!(conversion_format)
      end

      img         = image_processor.img
      img_quality = quality

      img.strip!

      blob = img.to_blob do
        self.quality   = img_quality
        self.interlace = (img.columns * img.rows <= 100 * 100) ? Magick::NoInterlace : Magick::PlaneInterlace
      end

      mime = img.mime_type

      [blob, mime]
    ensure
      image_processor.destroy!
    end
  end
end
