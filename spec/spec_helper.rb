ENV['RACK_ENV'] = 'test'

require "rspec"
require "rspec/autorun"
require 'macmillan/utils/statsd_stub'

require File.dirname(__FILE__) + "/../lib/image_resizer"

RSpec.configure do |config|
  config.before :suite do
    ImageResizer.init "test"

    logger       = Macmillan::Utils::Logger::Factory.build_logger
    logger.level = Logger::ERROR
    ImageResizer.logger = logger
    ImageResizer.statsd = Macmillan::Utils::StatsdStub.new
  end
end
