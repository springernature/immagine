require 'fileutils'

module Immagine
  class ImageProcessor
    attr_reader :img

    def initialize(source)
      @img = Magick::Image.read(source).first

      fail ProcessingError, "The width of the image #{source} is 0" if img.columns == 0
      fail ProcessingError, "The height of the image #{source} is 0" if img.rows == 0
    end

    def destroy!
      img.destroy!
    end

    def average_color
      target = img.dup
      target.scale!(1,1)
      pixel_color_at(0, 0, target)
    ensure
      target && target.destroy!
    end

    def dominant_color
      target = img.dup

      # scale to 100 x 100
      target.scale!(100, 100)

      # calculate 10 most domainant colours
      quantized = target.quantize(10, Magick::RGBColorspace)
      hist      = quantized.color_histogram.sort_by { |pixel, count| -count }.map(&:first).take(10)
      new_img   = Magick::Image.new(hist.size, 1)
      new_img.store_pixels(0, 0, hist.size, 1, hist)

      # pick the colour...
      lightness_threashold = 0.7
      top_10_colors        = (0..9).to_a.map { |i| pixel_color_at(i, 0, new_img) }
      potential            = top_10_colors.select { |col| col[:lightness] < lightness_threashold }

      chosen = if potential.any?
                 potential.first
               else
                 # if no colours meet the threashold, pick the darkest
                 top_10_colors.sort_by { |col| -col[:lightness] }.first
               end

      {
        top_10_colors: top_10_colors,
        chosen:        chosen
      }
    ensure
      target && target.destroy!
      quantized && quantized.destroy!
      new_img && new_img.destroy!
    end

    def overlay!(color = nil, percent = nil)
      color ||= dominant_color[:chosen][:hex]
      percent ||= 80
      overlay = Magick::Image.new(img.columns, img.rows, Magick::SolidFill.new(color))
      @img    = img.blend(overlay, "#{percent}%")
    ensure
      overlay && overlay.destroy!
    end

    def crop!(gravity, width, height)
      grav = case gravity
             when 'C'  then Magick::CenterGravity
             when 'N'  then Magick::NorthGravity
             when 'E'  then Magick::EastGravity
             when 'S'  then Magick::SouthGravity
             when 'W'  then Magick::WestGravity
             when 'NE' then Magick::NorthEastGravity
             when 'NW' then Magick::NorthWestGravity
             when 'SE' then Magick::SouthEastGravity
             when 'SW' then Magick::SouthWestGravity
             else
               fail ProcessingError, "Unsupported gravity argument '#{gravity}'"
             end

      img.crop!(grav, width, height)
    end

    def blur!(radius, sigma = nil)
      @img  = img.blur_image(radius, sigma || 1.0)
    end

    def constrain_width!(width)
      if img.columns <= width
        serve_image
      else
        resize_image_by_width!(width)
      end
    end

    def constrain_height!(height)
      if img.rows <= height
        serve_image
      else
        resize_image_by_height!(height)
      end
    end

    def resize_by_max!(size)
      if img.rows > img.columns # portrait
        constrain_height!(size)
      else # landscape
        constrain_width!(size)
      end
    end

    def resize_and_crop!(width, height)
      original_ratio = img.columns.to_f / img.rows.to_f
      target_ratio   = width.to_f / height.to_f

      resized = if target_ratio > original_ratio
                  resize_image_by_width!(width)
                else
                  resize_image_by_height!(height)
                end

      resized.crop!(Magick::CenterGravity, width, height)
    end

    def resize_relative_to_original!
      if img.columns <= 300
        serve_image
      elsif img.rows <= 1050
        resize_image_by_width!(300)
      else
        resize_by_max!(703)
      end
    end

    private

    def pixel_color_at(x, y, image = img)
      pix      = image.pixel_color(x, y)
      rgb      = { red: pix.red, green: pix.green, blue: pix.blue }
      h, s, l  = pix.to_HSL

      rgb.merge(hex: img.to_color(pix), luma: calculate_luma(rgb), hue: h, saturation: s, lightness: l)
    end

    def calculate_luma(rgb)
      # corr_fac is used to correct 16,32,64-bit RGB values to 8-bit precison
      corr_fac = 2**(Magick::MAGICKCORE_QUANTUM_DEPTH - 8)
      red      = rgb[:red] / corr_fac
      green    = rgb[:green] / corr_fac
      blue     = rgb[:blue] / corr_fac

      ((0.2126 * red) + (0.7152 * green) + (0.0722 * blue)).round
    end

    def resize_image_by_width!(width)
      scale_factor = width.to_f / img.columns.to_f
      resize!(scale_factor)
    end

    def resize_image_by_height!(height)
      scale_factor = height.to_f / img.rows.to_f
      resize!(scale_factor)
    end

    def resize!(scale_factor)
      img.resize!(scale_factor)
      serve_image
    end

    def serve_image
      img.compression = Magick::JPEGCompression if img.format == 'JPEG'
      img.interlace   = (img.columns * img.rows <= 100 * 100) ? Magick::NoInterlace : Magick::PlaneInterlace
      img
    end

    class ProcessingError < StandardError; end
  end
end
