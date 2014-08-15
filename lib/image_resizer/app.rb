module ImageResizer
  class App
    def logger
      ImageResizer.logger
    end

    def call(env)
      req = Rack::Request.new(env)
      if req.get?
        root(env, req.path)
      else
        not_found
      end
    end

    def root(env, image_path)
      parser = ImagePathParser.new
      dir, format_code, basename = parser.parse(image_path)

      source = File.join(ImageResizer.settings["source_folder"], dir, basename)

      return not_found unless ImageResizer.settings["size_whitelist"].include?(format_code)
      return not_found unless File.exist?(source)

      env['image_resizer.path'] = source
      env['image_resizer.format'] = format_code

      [200, {}, []]
    rescue ImagePathParser::ParseError
      logger.info "image path parsing error #{image_path}"
      return not_found
    ensure
      @processor.destroy! if @processor
    end

    def not_found
      content = "Not found"
      [404, { "Content-Length" => content.size.to_s }, [content]]
    end
  end
end
