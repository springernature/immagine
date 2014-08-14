require 'bundler'
require 'yaml'
require 'logger'
require 'RMagick'

base = File.dirname(__FILE__) + "/image_resizer"
%w(
  version
  app
  image_path_parser
  image_processor
  middleware
).each{ |lib| require "#{base}/#{lib}" }

module ImageResizer
  def self.init(environment)
    Bundler.require(:default, environment)
    load_settings(environment)
    init_logger(environment)
  end

  def self.init_logger(environment)
    @logger = if environment == "production"
      Logger::Syslog.new("image_resizer", Syslog::LOG_LOCAL0)
    else
      Logger.new(STDOUT)
    end
    @logger.level = Logger::INFO
  end

  def self.logger
    @logger
  end

  def self.settings
    @settings ||= {}
  end

  def self.settings=(settings)
    @settings = settings
  end

  def self.load_settings(environment)
    file_path = File.join(__dir__, "../config", "application.yml")
    all = YAML.load_file(file_path)
    settings = all[environment]
    raise "empty settings for environment `#{environment}`" if settings.nil?
    self.settings = settings
  end
end
