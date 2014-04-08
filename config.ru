require File.dirname(__FILE__) + "/lib/image_resizer.rb"

env = ENV["RACK_ENV"] || "development"
# use Rack::Sendfile
ImageResizer.init(env)
run ImageResizer::App.new
