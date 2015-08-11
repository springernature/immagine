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

  describe 'Requesting an original (non-resized) image' do
    context 'when the file exists' do
      it 'returns a 200 response' do
        get '/live/images/kitten.jpg'
        expect(last_response.status).to eq(200)
      end

      context 'Last-Modified HTTP headers' do
        it 'sets them' do
          get '/live/images/kitten.jpg'
          expect(last_response.header['Last-Modified']).to_not be_nil
        end
      end

      context 'ETAGS' do
        context 'when the file has not changed between requests' do
          it 'responds with the same Etags' do
            get '/live/images/kitten.jpg'
            expect(last_response).to be_ok

            first_etag = last_response.header['ETag']

            get '/live/images/kitten.jpg'
            expect(last_response).to be_ok
            expect(last_response.header['ETag']).to eq(first_etag)
          end
        end

        context 'when the file HAS changed between requests' do
          it 'responds with different Etags' do
            # there are 4 returns here as #send_file checks the mtime too
            expect(File)
              .to receive(:mtime)
              .and_return(Time.utc(2014, 1, 1), Time.utc(2014, 1, 1), Time.utc(2014, 1, 2), Time.utc(2014, 1, 2))

            get '/live/images/kitten.jpg'
            expect(last_response).to be_ok

            first_etag = last_response.header['ETag']

            get '/live/images/kitten.jpg'
            expect(last_response).to be_ok
            expect(last_response.header['ETag']).to_not eq(first_etag)
          end
        end
      end

      context 'Cache-Control' do
        context 'when a X-Cache-Control HTTP header HAS been passed' do
          it 'sets the cache and edge control headers accordingly for public resources' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public, max-age=60' }

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to eq('public, max-age=60')
            expect(last_response.header['Edge-Control']).to be_nil
          end

          it 'sets the cache and edge control headers accordingly for private resources' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'private, max-age=30' }

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to eq('private, max-age=30')
            expect(last_response.header['Edge-Control']).to eq('no-store, max-age=0')
          end
        end

        context 'when a X-Cache-Control HTTP header HAS NOT been passed' do
          context 'when the image requested is a LIVE asset' do
            it 'sets the Cache-Control as PUBLIC' do
              get "/live/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Cache-Control']).to include('public')
            end

            it 'sets the Max-Age as 1 day' do
              get "/live/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Cache-Control']).to include('max-age=86400')
            end
          end

          context 'when the image requested is a STAGING asset' do
            it 'sets the Cache-Control as PRIVATE' do
              get "/staging/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Cache-Control']).to include('private')
            end

            it 'sets Cache-Control as no-store' do
              get "/staging/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Cache-Control']).to include('no-store')
            end

            it 'sets the Max-Age as 0' do
              get "/staging/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Cache-Control']).to include('max-age=0')
            end

            it 'sets Edge-Control as no-store for Akamai' do
              get "/staging/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Edge-Control']).to include('no-store')
            end

            it 'sets the Edge-Control cache TTL for Akamai' do
              get "/staging/images/kitten.jpg"

              expect(last_response).to be_ok
              expect(last_response.header['Edge-Control']).to include('max-age=0')
            end
          end
        end
      end

      context 'stale cache revalidation' do
        context 'images cached for a year or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for a month' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public, max-age=31536000' }

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('2628000')
            expect(last_response.header['Stale-If-Error']).to eq('2628000')
          end
        end

        context 'images cached for a month or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for a week' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public, max-age=2628000' }

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('86400')
            expect(last_response.header['Stale-If-Error']).to eq('86400')
          end
        end

        context 'images cached for a week or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for an hour' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public, max-age=86400' }

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('3600')
            expect(last_response.header['Stale-If-Error']).to eq('3600')
          end
        end

        context 'images cached for an hour or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for a minute' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public, max-age=3600' }

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('60')
            expect(last_response.header['Stale-If-Error']).to eq('60')
          end
        end

        context 'images cached for less than an hour' do
          it 'does not set Stale-While-Revalidate and Stale-If-Error' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public, max-age=500' }

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to be_nil
            expect(last_response.header['Stale-If-Error']).to be_nil
          end
        end

        context 'images with no max-age' do
          it 'does not set Stale-While-Revalidate and Stale-If-Error' do
            get "/live/images/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'public' }

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to be_nil
            expect(last_response.header['Stale-If-Error']).to be_nil
          end
        end
      end
    end

    context 'when the file does not exist' do
      it 'returns a 404' do
        get '/live/images/matzwibble.jpg'
        expect(last_response.status).to eq(404)
      end

      it 'does not set cache-control headers' do
        get '/live/images/matzwibble.jpg'
        expect(last_response.header['Cache-Control']).to be_nil
      end
    end
  end

  describe 'Requesting a resized image' do
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
        get "/live/images/#{ImageResizer.settings.lookup('size_whitelist').sample}/bar.jpg"
        expect(last_response.status).to eq(404)
      end
    end

    context 'when everything is correct' do
      it 'returns a 200' do
        ImageResizer.settings.lookup('size_whitelist').each do |f|
          get "/live/images/#{f}/matz.jpg"
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'Last-Modified HTTP headers' do
      it 'sets them' do
        get "/live/images/#{ImageResizer.settings.lookup('size_whitelist').sample}/kitten.jpg"
        expect(last_response.header['Last-Modified']).to_not be_nil
      end
    end

    context 'ETAGS' do
      let(:format_code) { ImageResizer.settings.lookup('size_whitelist').sample }

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
          # called twice per request (for etags and last_modified)
          expect(File)
            .to receive(:mtime)
            .and_return(Time.utc(2014, 1, 1), Time.utc(2014, 1, 1), Time.utc(2014, 1, 2), Time.utc(2014, 1, 2))

          get "/live/images/#{format_code}/kitten.jpg"
          expect(last_response).to be_ok

          first_etag = last_response.header['ETag']

          get "/live/images/#{format_code}/kitten.jpg"
          expect(last_response).to be_ok
          expect(last_response.header['ETag']).to_not eq(first_etag)
        end
      end
    end

    context 'Cache-Control' do
      let(:format_code) { ImageResizer.settings.lookup('size_whitelist').sample }

      context 'when a X-Cache-Control HTTP header HAS been passed' do
        it 'sets the cache control headers accordingly' do
          get "/live/images/#{format_code}/kitten.jpg", {}, { 'HTTP_X_CACHE_CONTROL' => 'private, max-age=60' }

          expect(last_response).to be_ok
          expect(last_response.header['Cache-Control']).to eq('private, max-age=60')
        end
      end

      context 'when a X-Cache-Control HTTP header HAS NOT been passed' do
        context 'when the image requested is a LIVE asset' do
          it 'sets the Cache-Control as PUBLIC' do
            get "/live/images/#{format_code}/kitten.jpg"

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('public')
          end

          it 'sets the Max-Age as 1 day' do
            get "/live/images/#{format_code}/kitten.jpg"

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('max-age=86400')
          end
        end

        context 'when the image requested is a STAGING asset' do
          it 'sets the Cache-Control as PRIVATE' do
            get "/staging/images/#{format_code}/kitten.jpg"

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('private')
          end

          it 'sets the Max-Age as 0' do
            get "/staging/images/#{format_code}/kitten.jpg"

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('max-age=0')
          end
        end
      end
    end

    context 'Image Quality' do
      context 'no custom headers' do
        it 'uses the default image quality setting'
      end

      context 'with a X-Image-Quality HTTP header' do
        it 'uses the passed quality setting'
      end
    end
  end
end
