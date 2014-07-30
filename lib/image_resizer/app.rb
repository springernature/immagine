module ImageResizer
  class App
    def logger
      ImageResizer.logger
    end

    def call(env)
      req = Rack::Request.new(env)
      if req.get?
        root(req.path)
      else
        not_found
      end
    end

    def root(image_path)
      parser = ImagePathParser.new
      dir, format_code, basename = parser.parse(image_path)

      source = File.join(ImageResizer.settings["source_folder"], dir, basename)

      return not_found unless ImageResizer.settings["size_whitelist"].include?(format_code)
      return not_found unless File.exist?(source)

      @processor = ImageProcessor.new(source)

      image = case format_code
      when /\Aw(\d+)\z/
        @processor.constrain_width($1.to_i)
      when /\Ah(\d+)\z/
        @processor.constrain_height($1.to_i)
      when /\Am(\d+)\z/
        @processor.resize_by_max($1.to_i)
      when /\Aw(\d+)h(\d+)\z/
        @processor.resize_and_crop($1.to_i, $2.to_i)
      when /\Arelative\z/
        @processor.resize_relative_to_original
      else
        raise "Unsupported format: #{format_code}. Please remove it from the whitelist."
      end
      image.strip!
      send_file image
    rescue ImagePathParser::ParseError
      logger.info "image path parsing error #{image_path}"
      return not_found
    ensure
      @processor.destroy! if @processor
    end

    def send_file(image)
      data = image.to_blob { self.quality = 85 }
      headers = {
        "Content-Length" => data.length.to_s,
        "Content-Type"   => image.mime_type
      }
      headers['ETag']           ||= Digest::MD5.hexdigest(data)
      headers['Cache-Control']  ||= 'public, max-age=31557600'
      headers['Last-Modified']  ||= Time.new.httpdate

      [200, headers, [data]]
    end

    def not_found
      content = "Not found"
      [404, { "Content-Length" => content.size.to_s }, [content]]
    end
  end
end
