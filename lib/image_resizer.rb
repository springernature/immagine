require 'bundler'
require 'yaml'
require 'logger'
require 'RMagick'

require 'statsd-ruby'
require 'macmillan/utils'

module ImageResizer
  class << self
    def init(environment)
      Bundler.require(:default, environment)
      load_settings(environment)
    end

    def settings
      @settings ||= {}
    end

    attr_writer :settings

    def load_settings(environment)
      file_path = File.join(__dir__, '../config', 'application.yml')
      all = YAML.load_file(file_path)
      settings = all[environment]
      fail "empty settings for environment `#{environment}`" if settings.nil?
      self.settings = settings
    end

    def logger
      @logger ||= Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'image-resizer')
    end
    attr_writer :logger

    def statsd
      @statsd ||= begin
        environment      = ENV['RACK_ENV'] || 'development'
        statsd           = Statsd.new(settings['statsd_host'], settings['statsd_port'])
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
