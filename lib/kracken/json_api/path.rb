module Kracken
  module JsonApi
    class Path
      attr_reader :path_match

      def initialize(path)
        @path_match = Pathname(path).join('*').to_path
      end

      def matches?(request)
        request.supports_json_format? && request.path.fnmatch?(path_match)
      end
    end
  end
end
