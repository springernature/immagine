source 'http://rubygems.org'

gem "rake"
gem "rmagick", "~> 2.13.2", require: "RMagick"
gem "unicorn", "~> 4.8.1"
gem "syslog-logger"
gem 'macmillan-utils', git: 'git@github.com:nature/macmillan-utils.git', require: false

group :development, :test do
  gem "rspec"
  gem "rack-test", require: "rack/test"
  gem "pry"
end

gemspec
