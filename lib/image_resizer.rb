require 'bundler'
require 'yaml'
require 'logger'
require 'RMagick'

require 'statsd-ruby'
require 'macmillan/utils'

base = File.dirname(__FILE__) + "/image_resizer"
%w(
  version
  app
  image_path_parser
  image_processor
  middleware
).each{ |lib| require "#{base}/#{lib}" }

module ImageResizer
  class << self
    def init(environment)
      Bundler.require(:default, environment)
      load_settings(environment)
      init_logger(environment)
    end

    def init_logger(environment)
      @logger = if environment == "production"
        Logger::Syslog.new("image_resizer", Syslog::LOG_LOCAL0)
      else
        Logger.new(STDOUT)
      end
      @logger.level = Logger::INFO
    end

    def logger
      @logger
    end

    def settings
      @settings ||= {}
    end

    def settings=(settings)
      @settings = settings
    end

    def load_settings(environment)
      file_path = File.join(__dir__, "../config", "application.yml")
      all = YAML.load_file(file_path)
      settings = all[environment]
      raise "empty settings for environment `#{environment}`" if settings.nil?
      self.settings = settings
    end

    def statsd
      environment = ENV["RACK_ENV"] || "development" #FIXME
      @statsd ||= begin
        statsd = Statsd.new(settings['statsd_host'], settings['statsd_port'])
        statsd.namespace = "image-server-#{environment}"
        Macmillan::Utils::StatsdDecorator.new(statsd, environment, logger)
      end
    end
    attr_writer :statsd
  end
end
