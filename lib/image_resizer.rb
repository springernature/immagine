require 'bundler'
require 'yaml'
require 'logger'

require 'RMagick'
require_relative 'r_magick_image_analysis'

require 'statsd-ruby'
require 'macmillan/utils'

module ImageResizer
  class << self
    def init(environment)
      Bundler.require(:default, environment)
      settings
    end

    def settings
      @settings ||= begin
        Macmillan::Utils::Settings.backends = [Macmillan::Utils::Settings::AppYamlBackend]
        Macmillan::Utils::Settings.instance
      end
    end
    attr_writer :settings

    def logger
      @logger ||= Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'image-resizer')
    end
    attr_writer :logger

    def statsd
      @statsd ||= begin
        environment      = ENV['RACK_ENV'] || 'development'
        statsd           = Statsd.new(settings.lookup('statsd_host'), settings.lookup('statsd_port'))
        statsd.namespace = statsd_namespace
        Macmillan::Utils::StatsdDecorator.new(statsd, environment, logger)
      end
    end
    attr_writer :statsd

    def statsd_namespace
      hostname = `hostname`.chomp.downcase.gsub('.nature.com', '')
      tier     = hostname =~ /test/ ? 'test' : 'live'

      "image-server.#{tier}.#{hostname}"
    end
  end
end

require_relative 'image_resizer/image_processor'
require_relative 'image_resizer/service'
