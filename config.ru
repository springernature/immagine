$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

env = ENV['RACK_ENV'] || 'development'

require 'rack/contrib/try_static'
require 'image_resizer'

ImageResizer.init(env)

use Rack::CommonLogger, ImageResizer.logger
use Rack::TryStatic, urls: [''], root: ImageResizer.settings['source_folder']
run ImageResizer::Service.new
