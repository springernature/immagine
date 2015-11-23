module Immagine
  class VideoProcessor
    attr_reader :video

    VIDEO_FORMATS = %w(.mov .flv .mp4 .avi .mpg .wmv)

    def initialize(source)
      @video = FFMPEG::Movie.new(source)
    rescue Errno::ENOENT => ex
      log_error("Video processing not supported - #{ex}")
    end

    def screenshot(output_path)
      return nil unless video
      video.screenshot(output_path, seek_time: second)
    end

    private

    # FIXME: make second configurable somehow
    def second
      duration = video.duration
      second = if duration > 10
        10
      else
        (duration / 3).floor
      end
    end

    def log_error(msg)
      logger.error("[Immagine::Service] #{msg}")
    end

    def logger
      Immagine.logger
    end
  end
end