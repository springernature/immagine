# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'image_resizer/version'

Gem::Specification.new do |spec|
  spec.name          = "image_resizer"
  spec.version       = ImageResizer::VERSION
  spec.authors       = ["Andrea Franz"]
  spec.email         = ["a.franz@nature.com"]
  spec.description   = %q{An image resizer app and middleware}
  spec.summary       = %q{An image resizer app and middleware}
  spec.homepage      = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "shotgun"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec"

  spec.add_dependency "rmagick"
  spec.add_dependency "syslog-logger"
  spec.add_dependency 'statsd-ruby'
end
