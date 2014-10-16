require "rspec"
require "rspec/autorun"
require 'macmillan/utils/statsd_stub'

require File.dirname(__FILE__) + "/../lib/image_resizer"

RSpec.configure do |config|
  config.before :suite do
    ImageResizer.init "test"
    ImageResizer.logger.level = Logger::FATAL

    ImageResizer.statsd = Macmillan::Utils::StatsdStub.new
  end
end
