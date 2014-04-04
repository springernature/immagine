require 'bundler'
require "yaml"

base = File.dirname(__FILE__) + "/image_resizer"
%w(
  app
  image_path_parser
  image_processor
).each{ |lib| require "#{base}/#{lib}" }

module ImageResizer
  def self.init(environment)
    Bundler.require(:default, environment)
    load_settings(environment)
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
