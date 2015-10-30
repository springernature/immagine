module Immagine
  class FormatProcessor
    include Memoizable

    attr_reader :format_string

    # TODO: make quality part of this option

    REGEX = {
      height:   /h(\d+)/,
      width:    /w(\d+)/,
      max:      /m(\d+)/,
      relative: /rel/,
      crop:     /c([A-Z]{1,2})-([\d]+)-([\d]+)-?([\d\.]+)?/,
      blur:     /b([\d\.]+)-?([\d\.]+)?/,
      overlay:  /ov([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|dominant)?-?(\d{1,2})?/,
      convert:  /c([A-Z]{3,4})?/
    }

    def initialize(format_string)
      @format_string = format_string
    end

    def valid?
      if relative?
        valid_for_relative?
      elsif max
        valid_for_max?
      else
        valid_for_else?
      end
    end

    memoize def height
      extract_first_integer(:height)
    end

    memoize def width
      extract_first_integer(:width)
    end

    memoize def max
      extract_first_integer(:max)
    end

	memoize def relative?
      !!format_string.match(REGEX[:relative])
    end

    def crop?
      !!format_string.match(REGEX[:crop])
    end

    memoize def crop_gravity
      extract_first_match(:crop)
    end

    memoize def crop_width
      match = extract_second_match(:crop)
      match.to_i if match
    end

    memoize def crop_height
      match = extract_third_match(:crop)
      match.to_i if match
    end

    memoize def crop_resize_ratio
      match = extract_fourth_match(:crop)
      match.to_f if match
    end

    def blur?
      !!blur_radius
    end

    memoize def blur_radius
      match = extract_first_match(:blur)
      match.to_f if match
    end

    memoize def blur_sigma
      match = extract_second_match(:blur)
      match.to_f if match
    end

    memoize def overlay?
      !!format_string.match(REGEX[:overlay])
    end

    memoize def overlay_color
      match = extract_first_match(:overlay)
      return nil unless match
      match == 'dominant' ? nil : "##{match}"
    end

    memoize def overlay_opacity
      match = extract_second_match(:overlay)
      match.to_i if match
    end

    memoize def convert?
      !!format_string.match(REGEX[:convert])
    end

    memoize def conversion_type
      :convert[0] = ""
    end

    private

    def valid_for_relative?
      !(height || width || max)
    end

    def valid_for_max?
      !(height || width || relative?)
    end

    def valid_for_else?
      height || width || crop? || blur? || overlay? || convert?
    end

    def extract_first_integer(regex_key)
      match = extract_first_match(regex_key)
      match.to_i if match
    end

    def extract_first_match(regex_key)
      extract_n_match(1, regex_key)
    end

    def extract_second_match(regex_key)
      extract_n_match(2, regex_key)
    end

    def extract_third_match(regex_key)
      extract_n_match(3, regex_key)
    end

    def extract_fourth_match(regex_key)
      extract_n_match(4, regex_key)
    end

    def extract_n_match(n, regex_key)
      match = format_string.match(REGEX[regex_key])
      match[n] if match
    end
  end
end
