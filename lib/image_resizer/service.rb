require 'sinatra/base'
require 'json'

module ImageResizer
  class Service < Sinatra::Base

    before do
      http_headers = request.env.dup.select { |key, val| key =~ /\AHTTP_/ }
      http_headers.delete('HTTP_COOKIE')

      ImageResizer.logger.error "HTTP HEADERS:"
      ImageResizer.logger.error http_headers
    end

    get '/heartbeat' do
      'ok'
    end

    get %r{\A(.+)?/([^/]+)/([^/]+)\z} do |dir, format_code, basename|
      # check we have a dir
      if dir.to_s.empty?
        log_error('404, incorrect path, dir not extracted.')
        statsd.increment('dir_not_extracted')
        not_found
      end

      # check the format_code is on the whitelist
      unless ImageResizer.settings['size_whitelist'].include?(format_code)
        log_error("404, format code not found (#{format_code}).")
        statsd.increment('asset_format_not_in_whitelist')
        not_found
      end

      source_file = File.join(ImageResizer.settings['source_folder'], dir, basename)

      # check the file exists
      unless File.exist?(source_file)
        log_error("404, original file not found (#{source_file}).")
        statsd.increment('asset_not_found')
        not_found
      end

      # etags
      etag calculate_etags(dir, format_code, basename, source_file)

      # generate image
      image = statsd.time('asset_resize_request') do
        process_image(source_file, format_code)
      end

      # set content_type and headers
      content_type image.mime_type
      cache_control :public, max_age: 60

      image.to_blob { self.quality = 85 }
    end

    private

    def process_image(path, format)
      processor = ImageProcessor.new(path)

      image = case format
              when /\Aw(\d+)\z/
                processor.constrain_width($1.to_i)
              when /\Ah(\d+)\z/
                processor.constrain_height($1.to_i)
              when /\Am(\d+)\z/
                processor.resize_by_max($1.to_i)
              when /\Aw(\d+)h(\d+)\z/
                processor.resize_and_crop($1.to_i, $2.to_i)
              when /\Arelative\z/
                processor.resize_relative_to_original
              else
                raise "Unsupported format: #{format}. Please remove it from the whitelist."
              end

      image.strip!
      image
    end

    def calculate_etags(dir, format_code, basename, source_file)
      factors = [
        dir,
        format_code,
        basename,
        File.mtime(source_file)
      ].to_json

      Digest::MD5.hexdigest(factors)
    end

    def log_error(msg)
      logger.error("[ImageResizer::Service] (#{request.path}) - #{msg}")
    end

    def logger
      ImageResizer.logger
    end

    def statsd
      ImageResizer.statsd
    end
  end
end
