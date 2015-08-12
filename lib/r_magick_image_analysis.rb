module RMagickImageAnalysis
  def color_analysis
    {
      average_colour: average_color_and_luma
    }
  end

  def pixel_color_at(x, y)
    pix = pixel_color(x, y)
    rgb = [pix.red, pix.green, pix.blue]

    { rgb: rgb, hex: to_color(pix) }
  end

  private

  def average_color_and_luma
    target = self.dup
    target.scale(1,1)
    data = target.pixel_color_at(0, 0)

    data.merge(luma: calculate_luma(*data[:rgb]))
  end

  def calculate_luma(r, g, b)
    ((0.2126 * r) + (0.7152 * g) + (0.0722 * b)).round
  end
end
