require 'spec_helper'
require 'rack/test'

include Rack::Test::Methods

def app
  Rack::Builder.parse_file('config.ru').first
end

describe 'Requesting an original (unaltered) image' do
  it 'is ok' do
    get '/images/matz.jpg'
    expect(last_response).to be_ok
  end
end

describe 'Requesting a resized image' do
  describe 'When an invalid url is request' do
    it 'returns a 404' do
      get '/wrong_url'
      expect(last_response.status).to eq(404)
    end
  end

  describe 'When the format code is not in the whitelist' do
    it 'returns a 404' do
      get '/foo/wrong_format/bar.jpg'
      expect(last_response.status).to eq(404)
    end
  end

  describe 'When the source image does not exist' do
    it 'returns a 404' do
      get "/foo/#{ImageResizer.settings['size_whitelist'].sample}/bar.jpg"
      expect(last_response.status).to eq(404)
    end
  end

  describe 'When the format code is valid' do
    it 'returns a 200' do
      ImageResizer.settings['size_whitelist'].each do |f|
        get "/images/#{f}/matz.jpg"
        expect(last_response.status).to eq(200)
      end
    end
  end
end
