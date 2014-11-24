require 'spec_helper'
require 'rack/test'

describe ImageResizer::Service do
  include Rack::Test::Methods

  def app
    ImageResizer::Service
  end

  describe 'GET /heartbeat' do
    before do
      get '/heartbeat'
    end

    it "returns 'ok'" do
      expect(last_response.body).to eq('ok')
    end

    it 'returns a 200 response' do
      expect(last_response.status).to eq(200)
    end
  end

  describe 'Requesting an image' do
    context 'with an invaid URL (no dir)' do
      it 'returns a 404' do
        get '/live/bar.jpg'
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the format code is not in the whitelist' do
      it 'returns a 404' do
        get '/live/images/wrong_format/matz.jpg'
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the source image does not exist' do
      it 'returns a 404' do
        get "/live/images/#{ImageResizer.settings['size_whitelist'].sample}/bar.jpg"
        expect(last_response.status).to eq(404)
      end
    end

    context 'when everything is correct' do
      it 'returns a 200' do
        ImageResizer.settings['size_whitelist'].each do |f|
          get "/live/images/#{f}/matz.jpg"
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'ETAGS' do
      let(:format_code) { ImageResizer.settings['size_whitelist'].sample }

      context 'when the file HAS NOT been modified between requests' do
        it 'should return THE SAME ETAGs' do
          get "/live/images/#{format_code}/kitten.jpg"
          expect(last_response).to be_ok

          first_etag = last_response.header['ETag']

          get "/live/images/#{format_code}/kitten.jpg"
          expect(last_response).to be_ok
          expect(last_response.header['ETag']).to eq(first_etag)
        end
      end

      context 'when the file HAS been modified between requests' do
        it 'should return DIFFERENT ETAGs' do
          expect(File)
            .to receive(:mtime)
            .and_return(Time.utc(2014, 1, 1), Time.utc(2014, 1, 2))

          get "/live/images/#{format_code}/kitten.jpg"
          expect(last_response).to be_ok

          first_etag = last_response.header['ETag']

          get "/live/images/#{format_code}/kitten.jpg"
          expect(last_response).to be_ok
          expect(last_response.header['ETag']).to_not eq(first_etag)
        end
      end
    end
  end
end
