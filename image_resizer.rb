$LOAD_PATH.unshift __dir__

require 'sinatra/base'
require 'yaml'
require 'image_path_parser'
require 'image_processor'

class ImageResizer < Sinatra::Base
  configure do
    conf_file = File.join(__dir__, "config", "application.yml")
    conf = YAML.load(File.read(conf_file))
    conf.each do |key, value|
      set key.to_sym, value
    end
  end

  get '/*' do |img_path|
    begin
      parser = ImagePathParser.new
      dir, format_code, basename = parser.parse(img_path)
    rescue ImagePathParser::ParseError
      not_found
    end

    source = File.join(settings.source_folder, dir, basename)
    target = File.join(settings.target_folder, img_path)

    not_found unless settings.size_whitelist.include?(format_code)
    not_found unless File.exist?(source)

    processor = ImageProcessor.new(source, target)

    case format_code
    when /\Aw(\d+)\z/
      processor.constrain_width($1.to_i)
    when /\Ah(\d+)\z/
      processor.constrain_height($1.to_i)
    when /\Am(\d+)\z/
      processor.resize_by_max($1.to_i)
    when /\Aw(\d+)h(\d+)\z/
      processor.resize_and_crop($1.to_i, $2.to_i)
    else
      raise "Unsupported format: #{format_code}. Please remove it from the whitelist."
    end

    send_file target
  end
end
