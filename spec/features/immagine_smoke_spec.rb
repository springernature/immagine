require 'features/spec_helper'

feature 'Manipulating images via the immagine app' do
  scenario 'Successfully viewing a source image' do
    visit '/live/images/kitten.jpg'
    expect(page.status_code).to eq(200)
  end

  scenario 'Successfully performing image resizing' do
    visit '/live/images/w450/kitten.jpg'
    expect(page.status_code).to eq(200)
  end

  scenario 'Making sure that the image has indeed been resized' do
    visit '/live/images/w250/kitten.jpg'
    expect(width(page)).to eq(250)
  end

  scenario 'Successfully performing image format conversion' do
    visit '/live/images/kitten.jpg/convert/kitten.gif'
    expect(page.status_code).to eq(200)
  end

  scenario 'Successfully performing image resizing and format conversion' do
    visit '/live/images/w450/kitten.jpg/convert/kitten.gif'
    expect(page.status_code).to eq(200)
  end

  scenario 'Making sure that the image format has indeed been converted' do
    visit '/live/images/w250/kitten.jpg/convert/kitten.gif'
    expect(page.response_headers['Content-Type']).to eq('image/gif')
  end
end
