module ImageResizer
  class App
    def logger
      ImageResizer.logger
    end

    def call(env)
      req = Rack::Request.new(env)
      if req.get?
        return heartbeat if req.path == '/heartbeat'
        root(env, req.path)
      else
        not_found
      end
    end

    def root(env, image_path)
      parser = ImagePathParser.new
      dir, format_code, basename = parser.parse(image_path)

      source = File.join(ImageResizer.settings["source_folder"], dir, basename)

      unless ImageResizer.settings["size_whitelist"].include?(format_code)
        ImageResizer.statsd.increment('asset_format_not_in_whitelist')
        logger.error "404 - format code not found - '#{format_code}'"
        return not_found
      end

      unless File.exist?(source)
        ImageResizer.statsd.increment('asset_not_found')
        logger.error "404 - original file not found - #{source}"
        return not_found
      end

      env['image_resizer.path'] = source
      env['image_resizer.format'] = format_code

      logger.info "200 - serving resized image - #{format_code} - #{source}"

      [200, {}, []]
    rescue ImagePathParser::ParseError
      ImageResizer.statsd.increment('asset_parse_error')
      logger.info "404 - image path parsing error - #{image_path}"
      return not_found
    ensure
      @processor.destroy! if @processor
    end

    def not_found
      content = 'Not found'
      [404, { 'Content-Length' => content.size.to_s }, [content]]
    end

    def heartbeat
      content = 'ok'
      [200, { 'Content-Length' => content.size.to_s }, [content]]
    end
  end
end
