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
      crop:     /c([A-Z]{1,2})/,
      blur:     /b([\d\.]+)-?([\d\.]+)?/,
      overlay:  /ov#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|dominant)?/
    }

    def initialize(format_string)
      @format_string = format_string
    end

    def valid?
      if crop?
        valid_for_crop?
      elsif relative?
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
      !!crop_gravity
    end

    memoize def crop_gravity
      extract_first_match(:crop)
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

    private

    def valid_for_crop?
      if relative? || max
        false
      elsif height && width
        true
      else
        false
      end
    end

    def valid_for_relative?
      !(height || width || max || crop?)
    end

    def valid_for_max?
      !(height || width || crop? || relative?)
    end

    def valid_for_else?
      height || width || blur? || overlay?
    end

    def extract_first_integer(regex_key)
      match = extract_first_match(regex_key)
      match.to_i if match
    end

    def extract_first_match(regex_key)
      match = format_string.match(REGEX[regex_key])
      match[1] if match
    end

    def extract_second_match(regex_key)
      match = format_string.match(REGEX[regex_key])
      match[2] if match
    end
  end
end
