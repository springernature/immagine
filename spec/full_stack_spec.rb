require 'spec_helper'
require 'rack/test'

include Rack::Test::Methods

def app
  Rack::Builder.parse_file('config.ru').first
end

describe 'Requesting an original (unaltered) image' do
  it 'is ok' do
    get '/live/images/matz.jpg'
    expect(last_response).to be_ok
  end
end

describe 'Requesting a resized image' do
  describe 'when an image intended to exploit the imagetragick bug is requested' do
    it 'returns a 403 (forbidden)' do
      get "/live/images/#{Immagine.settings.lookup('format_whitelist').sample}/imagetragick.png"
      expect(last_response.status).to eq(403)
    end
  end

  describe 'When an invalid url is request' do
    it 'returns a 404' do
      get '/wrong_url'
      expect(last_response.status).to eq(404)
    end
  end

  describe 'When the format code is not in the whitelist' do
    context 'in production (non-development) mode' do
      it 'returns a 404' do
        get '/live/images/w200/matz.jpg'
        expect(last_response.status).to eq(404)
      end
    end

    context 'in development mode' do
      before do
        ENV['RACK_ENV'] = 'development'
      end

      after do
        ENV['RACK_ENV'] = 'test'
      end

      context 'and the format_code is valid' do
        it 'returns a 200' do
          get '/live/images/w200/matz.jpg'
          expect(last_response.status).to eq(200)
        end
      end

      context 'but the format_code is not valid' do
        it 'returns a 404' do
          get '/live/images/wrong_format/matz.jpg'
          expect(last_response.status).to eq(404)
        end
      end
    end
  end

  describe 'When the source image does not exist' do
    it 'returns a 404' do
      get "/live/foo/#{Immagine.settings.lookup('format_whitelist').sample}/bar.jpg"
      expect(last_response.status).to eq(404)
    end
  end

  describe 'When the format code is valid' do
    it 'returns a 200' do
      Immagine.settings.lookup('format_whitelist').each do |f|
        get "/live/images/#{f}/matz.jpg"
        expect(last_response.status).to eq(200)
      end
    end
  end
end
