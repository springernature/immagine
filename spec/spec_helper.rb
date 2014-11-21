ENV['RACK_ENV'] = 'test'

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/test_helpers/simplecov_helper'
require 'macmillan/utils/statsd_stub'

require 'image_resizer'

RSpec.configure do |config|
  config.before :suite do
    ImageResizer.init('test')

    logger       = Macmillan::Utils::Logger::Factory.build_logger(:null)
    logger.level = Logger::ERROR

    ImageResizer.logger = logger
    ImageResizer.statsd = Macmillan::Utils::StatsdStub.new
  end
end
