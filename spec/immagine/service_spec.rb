require 'spec_helper'
require 'rack/test'

describe Immagine::Service do
  include Rack::Test::Methods

  def app
    Immagine::Service
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

  describe 'Image colour analysis' do
    describe 'GET /analyse-test' do
      before do
        get '/analyse-test'
      end

      it 'returns a 200 response' do
        expect(last_response.status).to eq(200)
      end
    end

    describe 'GET /analyse/<IMAGE>' do
      context 'when the file exists' do
        it 'returns a 200 response' do
          get '/analyse/live/images/kitten.jpg'
          expect(last_response.status).to eq(200)
        end

        it 'returns a JSON object' do
          get '/analyse/live/images/kitten.jpg'

          expected_pixel_keys = %i(red green blue hex luma hue saturation lightness)
          json                = JSON.parse(last_response.body, symbolize_names: true)
          average_colour      = json.fetch(:average_color)
          dominant_color      = json.fetch(:dominant_color)

          expect(json.keys).to match_array(%i(file average_color dominant_color))
          expect(average_colour.keys).to match_array(expected_pixel_keys)
          expect(dominant_color.keys).to match_array(%i(top_10_colors chosen))
          expect(dominant_color.fetch(:top_10_colors).size).to eq(10)
          expect(dominant_color.fetch(:chosen).keys).to match_array(expected_pixel_keys)
        end

        context 'ETAGS' do
          context 'when the file has not changed between requests' do
            it 'responds with the same Etags' do
              get '/analyse/live/images/kitten.jpg'
              expect(last_response).to be_ok

              first_etag = last_response.header['ETag']

              get '/analyse/live/images/kitten.jpg'
              expect(last_response).to be_ok
              expect(last_response.header['ETag']).to eq(first_etag)
            end
          end

          context 'when the file HAS changed between requests' do
            it 'responds with different Etags' do
              expect(File)
                .to receive(:mtime)
                .and_return(Time.utc(2014, 1, 1), Time.utc(2014, 1, 1), Time.utc(2014, 1, 2), Time.utc(2014, 1, 2))

              get '/analyse/live/images/kitten.jpg'
              expect(last_response).to be_ok

              first_etag = last_response.header['ETag']

              get '/analyse/live/images/kitten.jpg'
              expect(last_response).to be_ok
              expect(last_response.header['ETag']).to_not eq(first_etag)
            end
          end
        end
      end

      context 'when the file does not exist' do
        it 'returns a 404' do
          get '/analyse/live/images/matzwibble.jpg'
          expect(last_response.status).to eq(404)
        end
      end
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
        context 'when the image requested is NOT a STAGING asset' do
          it 'sets the Cache-Control as PUBLIC' do
            get '/live/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('public')
          end

          it 'sets the Max-Age as 30 days' do
            get '/uploads/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('max-age=2592000')
          end
        end

        context 'when the image requested is a STAGING asset' do
          it 'sets the Cache-Control as PRIVATE' do
            get '/staging/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('private')
          end

          it 'sets Cache-Control as no-store' do
            get '/staging/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('no-store')
          end

          it 'sets the Max-Age as 0' do
            get '/staging/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Cache-Control']).to include('max-age=0')
          end

          it 'sets Edge-Control as no-store for Akamai' do
            get '/staging/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Edge-Control']).to include('no-store')
          end

          it 'sets the Edge-Control cache TTL for Akamai' do
            get '/staging/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Edge-Control']).to include('max-age=0')
          end
        end
      end

      context 'stale cache revalidation' do
        context 'images cached for a year or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for a month' do
            stub_const('Immagine::Service::DEFAULT_EXPIRES', 31_536_000)

            get '/live/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('2628000')
            expect(last_response.header['Stale-If-Error']).to eq('2628000')
          end
        end

        context 'images cached for a month or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for a week' do
            stub_const('Immagine::Service::DEFAULT_EXPIRES', 2_628_000)

            get '/live/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('86400')
            expect(last_response.header['Stale-If-Error']).to eq('86400')
          end
        end

        context 'images cached for a week or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for an hour' do
            stub_const('Immagine::Service::DEFAULT_EXPIRES', 86_400)

            get '/live/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('3600')
            expect(last_response.header['Stale-If-Error']).to eq('3600')
          end
        end

        context 'images cached for an hour or more' do
          it 'sets Stale-While-Revalidate and Stale-If-Error for a minute' do
            stub_const('Immagine::Service::DEFAULT_EXPIRES', 3600)

            get '/live/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to eq('60')
            expect(last_response.header['Stale-If-Error']).to eq('60')
          end
        end

        context 'images cached for less than an hour' do
          it 'does not set Stale-While-Revalidate and Stale-If-Error' do
            stub_const('Immagine::Service::DEFAULT_EXPIRES', 500)

            get '/live/images/kitten.jpg'

            expect(last_response).to be_ok
            expect(last_response.header['Stale-While-Revalidate']).to be_nil
            expect(last_response.header['Stale-If-Error']).to be_nil
          end
        end

        context 'images with no max-age' do
          it 'does not set Stale-While-Revalidate and Stale-If-Error' do
            stub_const('Immagine::Service::DEFAULT_EXPIRES', 0)

            get '/live/images/kitten.jpg'

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
        get "/live/images/#{Immagine.settings.lookup('format_whitelist').sample}/bar.jpg"
        expect(last_response.status).to eq(404)
      end
    end

    context 'when everything is correct' do
      it 'returns a 200' do
        Immagine.settings.lookup('format_whitelist').each do |f|
          get "/live/images/#{f}/matz.jpg"
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'Last-Modified HTTP headers' do
      it 'sets them' do
        get "/live/images/#{Immagine.settings.lookup('format_whitelist').sample}/kitten.jpg"
        expect(last_response.header['Last-Modified']).to_not be_nil
      end
    end

    context 'ETAGS' do
      let(:format_code) { Immagine.settings.lookup('format_whitelist').sample }

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
      let(:format_code) { Immagine.settings.lookup('format_whitelist').sample }

      context 'when the image requested is NOT a STAGING asset' do
        it 'sets the Cache-Control as PUBLIC' do
          get "/live/images/#{format_code}/kitten.jpg"

          expect(last_response).to be_ok
          expect(last_response.header['Cache-Control']).to include('public')
        end

        it 'sets the Max-Age as 30 days' do
          get "/uploads/images/#{format_code}/kitten.jpg"

          expect(last_response).to be_ok
          expect(last_response.header['Cache-Control']).to include('max-age=2592000')
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

    context 'Image Quality' do
      let(:format_code) { Immagine.settings.lookup('format_whitelist').sample }
      let(:img_source)  { '/live/images/kitten.jpg' }
      let(:file_path)   { File.join(Immagine.settings.lookup('source_folder'), img_source) }

      context 'no custom headers' do
        it 'uses the default image quality setting' do
          expect_any_instance_of(Immagine::Service)
            .to receive(:process_image)
            .with(file_path, format_code, Immagine::Service::DEFAULT_IMAGE_QUALITY, nil)
            .and_call_original

          get "/live/images/#{format_code}/kitten.jpg"

          expect(last_response).to be_ok
        end
      end

      context 'with a X-Image-Quality HTTP header' do
        let(:quality) { Immagine::Service::DEFAULT_IMAGE_QUALITY - 20 }

        it 'uses the passed quality setting' do
          expect_any_instance_of(Immagine::Service)
            .to receive(:process_image)
            .with(file_path, format_code, quality, nil)
            .and_call_original

          header 'X_IMAGE_QUALITY', quality
          get "/live/images/#{format_code}/kitten.jpg"

          expect(last_response).to be_ok
        end
      end
    end

    context 'Image Encoding for JPEGs' do
      # http://en.wikipedia.org/wiki/JPEG
      # SOF2 [255, 194] = Start Of Frame (Progressive DCT)

      it 'uses progressive encoding for large images' do
        get '/live/images/m685/kitten.jpg'

        expect(last_response).to be_ok
        expect(last_response.body.bytes.join(',')).to include('255,194')
      end

      it 'uses baseline encoding for thumbnails' do
        get '/live/images/w100h100/kitten.jpg'

        expect(last_response).to be_ok
        expect(last_response.body.bytes.join(',')).to_not include('255,194')
      end
    end

    context 'and converting to a different file type' do
      file_types = %w(jpg png JPG PNG)

      context 'when an allowed file type is requested' do
        let(:driver) { double(Immagine::ImageProcessorDriver, process: nil) }
        file_types.each do |to_format|
          it "converts to #{to_format}" do
            expect(Immagine::ImageProcessorDriver).to receive(:new).with(
              anything, anything, to_format.downcase.to_sym, anything
            ).and_return(driver)

            get "/live/images/w100h100/kitten.jpg/convert/kitten.#{to_format}"
          end
        end
      end

      context 'when a disallowed file type is requested' do
        it 'returns a 404' do
          get '/live/images/m685/kitten.jpg/convert/kitten.tiff'
          expect(last_response.status).to eq(404)
        end
      end
    end
  end

  describe 'video thumbnails' do
    context 'when the file exists' do
      it 'returns a 200 response' do
        get '/live/videos/cat-vs-food.mp4'
        expect(last_response.status).to eq(200)
      end

      it 'returns a thumbnail for the video' do
        get '/live/videos/w100h100/cat-vs-food.mp4'
        expect(last_response.status).to eq(200)
      end
    end
  end
end
