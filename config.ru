$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

env = ENV['RACK_ENV'] || 'development'

require 'image_resizer'

ImageResizer.init(env)

use Rack::CommonLogger, ImageResizer.logger
run ImageResizer::Service.new
