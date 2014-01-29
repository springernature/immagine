require 'rack/test'
require 'minitest/autorun'

include Rack::Test::Methods

def app
  rackup_file = File.join(File.dirname(__FILE__), "..", "config.ru")
  Rack::Builder.parse_file(rackup_file).first
end

describe "Requesting an image" do
  describe "When an invalid url is request" do
    it "returns a 404" do
      get '/wrong_url'
      last_response.status.must_equal 404
    end
  end

  describe "When the format code is not in the whitelist" do
    it "returns a 404" do
      get "/foo/wrong_format/bar.jpg"
      last_response.status.must_equal 404
    end
  end

  describe "When the source image does not exist" do
    it "returns a 404" do
      get "/foo/w300/bar.jpg"
      last_response.status.must_equal 404
    end
  end

  describe "When the format code is valid" do
    it "returns a 200" do
      get "/images/w300/matz.jpg"
      last_response.status.must_equal 200
    end
  end
end
