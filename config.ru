$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

env = ENV['RACK_ENV'] || 'development'

require 'immagine'

Immagine.init(env)

use Rack::CommonLogger, Immagine.logger
run Immagine::Service.new
