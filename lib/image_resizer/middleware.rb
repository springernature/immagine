module ImageResizer
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      http_headers = env.select { |k,v| k =~ /^HTTP_/ }
      http_headers.delete("HTTP_COOKIE")

      ImageResizer.logger.error "HTTP HEADERS:"
      ImageResizer.logger.error http_headers

      path    = env['image_resizer.path']
      format  = env['image_resizer.format']
      if status == 200 && path.to_s != '' && format.to_s != ''
        ImageResizer.statsd.time('asset_resize_request') do
          process_image(path, format)
        end
      else
        [status, headers, response]
      end
    end

    private

    def process_image(path, format)
      @processor = ImageProcessor.new(path)

      image = case format
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
        raise "Unsupported format: #{format}. Please remove it from the whitelist."
      end
      image.strip!
      send_file image
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
  end
end
