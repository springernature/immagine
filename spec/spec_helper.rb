ENV['RACK_ENV'] = 'test'

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/test_helpers/simplecov_helper'
require 'macmillan/utils/statsd_stub'

require 'immagine'

RSpec.configure do |config|
  config.before :suite do
    Immagine.init('test')

    logger       = Macmillan::Utils::Logger::Factory.build_logger(:null)
    logger.level = Logger::ERROR

    Immagine.logger = logger
    Immagine.statsd = Macmillan::Utils::StatsdStub.new
  end
end
