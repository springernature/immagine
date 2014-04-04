require "spec_helper"
require "rack/test"

include Rack::Test::Methods

def app
  ImageResizer::App
end

describe "Requesting an image" do
  describe "When an invalid url is request" do
    it "returns a 404" do
      get '/wrong_url'
      expect(last_response.status).to eq(404)
    end
  end

  describe "When the format code is not in the whitelist" do
    it "returns a 404" do
      get "/foo/wrong_format/bar.jpg"
      expect(last_response.status).to eq(404)
    end
  end

  describe "When the source image does not exist" do
    it "returns a 404" do
      get "/foo/w300/bar.jpg"
      expect(last_response.status).to eq(404)
    end
  end

  describe "When the format code is valid" do
    it "returns a 200" do
      ImageResizer.settings["size_whitelist"].each do |f|
        get "/images/#{f}/matz.jpg"
        expect(last_response.status).to eq(200)
      end
    end
  end
end
