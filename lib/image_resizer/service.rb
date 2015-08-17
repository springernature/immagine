require 'sinatra/base'
require 'json'

module ImageResizer
  class Service < Sinatra::Base
    DEFAULT_IMAGE_QUALITY = 85

    configure do
      set :root, File.join(File.dirname(__FILE__), 'service')
    end

    before do
      http_headers = request.env.dup.select { |key, _val| key =~ /\AHTTP_/ }
      http_headers.delete('HTTP_COOKIE')
    end

    get '/heartbeat' do
      'ok'
    end

    get '/analyse-test' do
      image_dir = File.join(ImageResizer.settings.lookup('source_folder'), '..', 'analyse-test')
      @images   = Dir.glob("#{image_dir}/*").map do |source|
        image = Magick::Image.read(source).first.extend(RMagickImageAnalysis)
        color_analysis = image.color_analysis
        image.destroy!

        {
          file: source.sub(image_dir, '/analyse-test')
        }.merge(color_analysis)
      end.compact

      erb :analyse_test
    end

    get %r{\A/analyse/(.+)\z} do |path|
      source = File.join(ImageResizer.settings.lookup('source_folder'), path)
      not_found unless File.exist?(source)

      etag calculate_etags('wibble', 'wobble', source, source)

      image          = Magick::Image.read(source).first.extend(RMagickImageAnalysis)
      color_analysis = image.color_analysis
      image.destroy!

      content_type :json

      {
        file: path
      }.merge(color_analysis).to_json
    end

    get %r{\A(.+)?/([^/]+)/([^/]+)\z} do |dir, format_code, basename|
      # check we have a dir
      if dir.to_s.empty?
        log_error('404, incorrect path, dir not extracted.')
        statsd.increment('dir_not_extracted')
        not_found
      end

      # check to see if this is an *actual* filepath
      static_file = File.join(ImageResizer.settings.lookup('source_folder'), dir, format_code, basename)

      if File.exist?(static_file)
        etag calculate_etags(dir, format_code, basename, static_file)
        set_cache_control_headers(request, dir)

        statsd.increment('serve_original_image')
        send_file static_file
      end

      # check the format_code is on the whitelist
      unless ImageResizer.settings.lookup('size_whitelist').include?(format_code)
        log_error("404, format code not found (#{format_code}).")
        statsd.increment('asset_format_not_in_whitelist')
        not_found
      end

      source_file = File.join(ImageResizer.settings.lookup('source_folder'), dir, basename)

      # check the file exists
      unless File.exist?(source_file)
        log_error("404, original file not found (#{source_file}).")
        statsd.increment('asset_not_found')
        not_found
      end

      # etags & cache headers
      etag calculate_etags(dir, format_code, basename, source_file)
      last_modified File.mtime(source_file)
      set_cache_control_headers(request, dir)

      # generate image
      image = statsd.time('asset_resize') do
        process_image(source_file, format_code)
      end

      # content type
      content_type image.mime_type

      # image quality
      image_quality = Integer(request.env['HTTP_X_IMAGE_QUALITY'] || DEFAULT_IMAGE_QUALITY)

      return_obj = image.to_blob { self.quality = image_quality }

      image.destroy!

      return_obj
    end

    private

    def set_cache_control_headers(request, dir)
      if custom_cache_control = request.env['HTTP_X_CACHE_CONTROL']
        cache_control custom_cache_control
      elsif dir =~ %r{\A/live}
        cache_control :public, max_age: 86_400
      else
        cache_control :private, :no_store, max_age: 0
      end

      prevent_storage_on_akamai if response['Cache-Control'].include? 'private'

      set_stale_headers
    end

    def set_stale_headers
      if response['Cache-Control'] =~ /max-age=(\d+)/
        max_age   = Regexp.last_match[1].to_i
        stale_age = if max_age >= 31_536_000
                      2_628_000
                    elsif max_age >= 2_628_000
                      86_400
                    elsif max_age >= 86_400
                      3600
                    elsif max_age >= 3600
                      60
                    else
                      0
                    end

        if stale_age > 0
          response['Stale-While-Revalidate'] = stale_age.to_s
          response['Stale-If-Error']         = stale_age.to_s
        end
      end
    end

    def prevent_storage_on_akamai
      response['Edge-Control'] = 'no-store, max-age=0'
    end

    def process_image(path, format)
      processor = ImageProcessor.new(path)

      image = case format
              when /\Aw(\d+)\z/
                processor.constrain_width(Regexp.last_match[1].to_i)
              when /\Ah(\d+)\z/
                processor.constrain_height(Regexp.last_match[1].to_i)
              when /\Am(\d+)\z/
                processor.resize_by_max(Regexp.last_match[1].to_i)
              when /\Aw(\d+)h(\d+)\z/
                processor.resize_and_crop(Regexp.last_match[1].to_i, Regexp.last_match[2].to_i)
              when /\Arelative\z/
                processor.resize_relative_to_original
              else
                fail "Unsupported format: #{format}. Please remove it from the whitelist."
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
