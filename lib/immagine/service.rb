require 'sinatra/base'
require 'tilt/erb'
require 'json'

module Immagine
  class Service < Sinatra::Base
    DEFAULT_IMAGE_QUALITY = 85
    DEFAULT_EXPIRES       = 30 * 24 * 60 * 60 # 30 days in seconds

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
      image_dir = File.join(Immagine.settings.lookup('source_folder'), '..', 'analyse-test')

      Dir.chdir(image_dir) do
        @images = Dir.glob('*').map do |source|
          analyse_color(source).merge(file: File.join('/analyse-test', source))
        end.compact
      end

      erb :analyse_test
    end

    get %r{\A/analyse/(.+)\z} do |path|
      source = File.join(Immagine.settings.lookup('source_folder'), path)
      not_found unless File.exist?(source)

      etag(calculate_etags('wibble', 'wobble', source, source))
      last_modified(File.mtime(source))

      content_type :json
      analyse_color(source).merge(file: path).to_json
    end

    get %r{\A(.+)?/([^/]+)/([^/]+)\z} do |dir, format_code, basename|
      # check we have a dir
      if dir.to_s.empty?
        log_error('404, incorrect path, dir not extracted.')
        statsd.increment('dir_not_extracted')
        not_found
      end

      # check to see if this is an *actual* filepath
      static_file = File.join(Immagine.settings.lookup('source_folder'), dir, format_code, basename)

      if File.exist?(static_file)
        etag(calculate_etags(dir, format_code, basename, static_file))
        set_cache_control_headers(request, dir)
        statsd.increment('serve_original_image')
        send_file(static_file)
      end

      # FIXME: make it so we don't consider the whitelist in development mode?
      # FIXME: make the whitelist optional?

      # check the format_code is on the whitelist
      unless Immagine.settings.lookup('size_whitelist').include?(format_code) && format_processor(format_code).valid?
        log_error("404, format code not found (#{format_code}).")
        statsd.increment('asset_format_not_in_whitelist')
        not_found
      end

      source_file = File.join(Immagine.settings.lookup('source_folder'), dir, basename)

      # check the file exists
      unless File.exist?(source_file)
        log_error("404, original file not found (#{source_file}).")
        statsd.increment('asset_not_found')
        not_found
      end

      # etags & cache headers
      etag(calculate_etags(dir, format_code, basename, source_file))
      last_modified(File.mtime(source_file))
      set_cache_control_headers(request, dir)

      # generate image
      image_blob, mime = statsd.time('asset_resize') do
        quality = Integer(request.env['HTTP_X_IMAGE_QUALITY'] || DEFAULT_IMAGE_QUALITY)
        process_image(source_file, format_code, quality)
      end

      # content type
      content_type(mime)

      image_blob
    end

    private

    def set_cache_control_headers(request, dir)
      if dir.match(%r{\A/staging})
        # FIXME: make this configurable - i.e. the /staging path being treated special like...
        cache_control(:private, :no_store, max_age: 0)
      else
        expires(DEFAULT_EXPIRES, :public)
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

    def process_image(path, format, quality)
      image_proc  = image_processor(path)
      format_proc = format_processor(format)

      fail "Unsupported format: '#{format}'" unless format_proc.valid?
      ImageProcessorDriver.new(image_proc, format_proc, quality).process
    end

    def image_processor(path)
      ImageProcessor.new(path)
    end

    def format_processor(format)
      FormatProcessor.new(format)
    end

    def analyse_color(path)
      image = image_processor(path)

      {
        average_color:  image.average_color,
        dominant_color: image.dominant_color
      }
    ensure
      image && image.destroy!
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
      logger.error("[Immagine::Service] (#{request.path}) - #{msg}")
    end

    def logger
      Immagine.logger
    end

    def statsd
      Immagine.statsd
    end
  end
end
