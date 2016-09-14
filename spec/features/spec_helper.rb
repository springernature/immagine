require 'capybara/rspec'
require 'capybara/poltergeist'

# SET CAPYBARA DRIVER:
Capybara.register_driver :poltergeist do |app|
  options = {
    js_errors:         false,
    timeout:           120,
    debug:             false,
    phantomjs_options: ['--load-images=yes', '--disk-cache=false'],
    inspector:         true
  }

  Capybara::Poltergeist::Driver.new(app, options)
end

# CONFIGURE CAPYBARA:
Capybara.configure do |c|
  c.default_driver    = :poltergeist
  c.current_driver    = :poltergeist
  c.javascript_driver = :poltergeist
  c.app_host          = 'http://localhost:3000'

  c.include Capybara::DSL
  c.include Capybara::RSpecMatchers
end

def width(page)
  page.driver.evaluate_script <<-EOS
    function() {
      var image  = document.getElementsByTagName('img')[0];
      var width  = image.clientWidth;
      return width;
    }();
  EOS
end
