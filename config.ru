require 'rack/contrib/try_static'
require File.dirname(__FILE__) + "/lib/image_resizer.rb"

env = ENV["RACK_ENV"] || "development"
ImageResizer.init(env)

use Rack::TryStatic, urls: [''], root: ImageResizer.settings['source_folder']
use ImageResizer::Middleware
run ImageResizer::App.new
