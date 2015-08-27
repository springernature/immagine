require 'spec_helper'

describe Immagine::FormatProcessor do
  subject { described_class.new(format) }

  describe '#valid?' do
    context 'The pre-configured size_whitelist' do
      Immagine.settings.lookup('size_whitelist').each do |code|
        describe "#{code}" do
          it { expect(described_class.new(code)).to be_valid }
        end
      end
    end

    context 'Good formats' do
      %w(
        rel
        relb2
        m500
        cNWh100w100
        b12.1
        b1.1-11
        b1.1-11.1
        b10m100
        b10h100w100
        b10cNWh100w100
        h100
        w100
        h100w100
      ).each do |code|
        describe "#{code}" do
          it { expect(described_class.new(code)).to be_valid }
        end
      end
    end

    context 'Bad formats' do
      %w(
        h100rel
        relw120
        cNh100
        cNw100
        cNh100w100rel
        m100rel
        m100cN
        m100h100
        m100w100
      ).each do |code|
        describe "#{code}" do
          it { expect(described_class.new(code)).to_not be_valid }
        end
      end
    end
  end

  context 'rel' do
    let(:format) { 'rel' }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to be_nil }
    end

    describe '#width' do
      it { expect(subject.width).to be_nil }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_truthy }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_falsey }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to be_nil }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'hXXX' do
    let(:format) { "h#{height}" }
    let(:height) { 200 }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to eq(height) }
    end

    describe '#width' do
      it { expect(subject.width).to be_nil }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_falsey }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to be_nil }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'wXXX' do
    let(:format) { "w#{width}" }
    let(:width) { 200 }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to be_nil }
    end

    describe '#width' do
      it { expect(subject.width).to eq(width) }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_falsey }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to be_nil }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'bXX-XX' do
    let(:format)      { "b#{blur_radius}-#{blur_sigma}" }
    let(:blur_radius) { 2.1 }
    let(:blur_sigma)  { 1.5 }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to be_nil }
    end

    describe '#width' do
      it { expect(subject.width).to be_nil }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_truthy }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to eq(blur_radius) }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to eq(blur_sigma) }
    end
  end

  context 'hXXXwXXX' do
    let(:format) { "h#{height}w#{width}" }
    let(:height) { 200 }
    let(:width)  { 200 }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to eq(height) }
    end

    describe '#width' do
      it { expect(subject.width).to eq(width) }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_falsey }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to be_nil }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'cXXhXXXwXXX' do
    let(:format)  { "c#{gravity}h#{height}w#{width}" }
    let(:height)  { 200 }
    let(:width)   { 200 }
    let(:gravity) { 'C' }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to eq(height) }
    end

    describe '#width' do
      it { expect(subject.width).to eq(width) }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_truthy }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to eq(gravity) }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_falsey }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to be_nil }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'bXXhXXXwXXX' do
    let(:format)  { "b#{blur}h#{height}w#{width}" }
    let(:height)  { 200 }
    let(:width)   { 200 }
    let(:blur)    { 2 }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to eq(height) }
    end

    describe '#width' do
      it { expect(subject.width).to eq(width) }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_truthy }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to eq(2) }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'bXXcXXhXXXwXXX' do
    let(:format)  { "b#{blur}c#{gravity}h#{height}w#{width}" }
    let(:height)  { 200 }
    let(:width)   { 200 }
    let(:gravity) { 'NW' }
    let(:blur)    { 2.0 }

    describe '#max' do
      it { expect(subject.max).to be_nil }
    end

    describe '#height' do
      it { expect(subject.height).to eq(height) }
    end

    describe '#width' do
      it { expect(subject.width).to eq(width) }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_truthy }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to eq('NW') }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_truthy }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to eq(blur) }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end

  context 'bXXmXXX' do
    let(:format)  { "b#{blur}m#{max}" }
    let(:max)     { 200 }
    let(:blur)    { 3 }

    describe '#max' do
      it { expect(subject.max).to eq(max) }
    end

    describe '#height' do
      it { expect(subject.height).to be_nil }
    end

    describe '#width' do
      it { expect(subject.width).to be_nil }
    end

    describe '#relative?' do
      it { expect(subject.relative?).to be_falsey }
    end

    describe '#crop?' do
      it { expect(subject.crop?).to be_falsey }
    end

    describe '#crop_gravity' do
      it { expect(subject.crop_gravity).to be_nil }
    end

    describe '#blur?' do
      it { expect(subject.blur?).to be_truthy }
    end

    describe '#blur_radius' do
      it { expect(subject.blur_radius).to eq(blur) }
    end

    describe '#blur_sigma' do
      it { expect(subject.blur_sigma).to be_nil }
    end
  end
end
