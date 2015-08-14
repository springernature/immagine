module RMagickImageAnalysis
  def color_analysis
    {
      average_colour:  average_color,
      dominant_colour: dominant_colour
    }
  end

  def pixel_color_at(x, y, img = self)
    pix      = img.pixel_color(x, y)
    rgb      = { red: pix.red, green: pix.green, blue: pix.blue }
    h, s, l  = pix.to_HSL

    rgb.merge(hex: to_color(pix), luma: calculate_luma(rgb), hue: h, saturation: s, lightness: l)
  end

  private

  def dominant_colour
    target        = self.dup
    base_filename = target.filename.dup

    ##
    ## scale to 100 x 100
    ##

    target.scale!(100, 100)

    ##
    ## calculate 10 most domainant colours
    ##

    quantized = target.quantize(10, Magick::RGBColorspace)
    hist      = quantized.color_histogram.sort_by { |pixel, count| -count }.map(&:first).take(10)
    new_img   = Magick::Image.new(hist.size, 1)
    new_img.store_pixels(0, 0, hist.size, 1, hist)

    ##
    ## pick the colour...
    ##

    lightness_threashold = 0.7
    top_10_colors        = (0..9).to_a.map { |i| pixel_color_at(i,0,new_img) }
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
  end

  def average_color
    target = self.dup
    target.scale(1,1)
    data = target.pixel_color_at(0, 0)

    data.merge(luma: calculate_luma(*data[:rgb]))
  ensure
    target && target.destroy!
  end

  def calculate_luma(rgb)
    # corr_fac is used to correct 16,32,64-bit RGB values to 8-bit precison
    corr_fac =  2 ** (Magick::MAGICKCORE_QUANTUM_DEPTH - 8)
    red      = rgb[:red] / corr_fac
    green    = rgb[:green] / corr_fac
    blue     = rgb[:blue] / corr_fac

    ((0.2126 * red) + (0.7152 * green) + (0.0722 * blue)).round
  end
end
