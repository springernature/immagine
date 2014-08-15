require File.dirname(__FILE__) + "/lib/image_resizer.rb"

env = ENV["RACK_ENV"] || "development"
ImageResizer.init(env)

use ImageResizer::Middleware
run ImageResizer::App.new
