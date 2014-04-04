require "rspec"
require "rspec/autorun"
require File.dirname(__FILE__) + "/../lib/image_resizer"

RSpec.configure do |config|
  config.before :suite do
    ImageResizer.init "test"
  end
end
