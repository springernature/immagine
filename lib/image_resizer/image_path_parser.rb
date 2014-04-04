module ImageResizer
  class ImagePathParser
    def parse(path)
      raise ParseError if path =~ /\.\./ # Just to be sure we can't go up the tree
      matches = path.scan /\A(.+)\/([^\/]+)\/([^\/]+)\z/
      raise ParseError unless matches.size == 1
      matches.first
    end

    class ParseError < StandardError; end
  end
end
