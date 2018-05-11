# frozen_string_literal: true

module Kracken
  module JsonApi
    class Path
      attr_reader :basename
      attr_reader :pathname

      def initialize(path)
        @basename = ActionDispatch::Journey::Router::Utils.normalize_path(path)
        @pathname = @basename + "/"
      end

      def matches?(request)
        path_matches?(request.original_fullpath)
      end

    private

      def path_matches?(path)
        path == basename || path.start_with?(pathname)
      end
    end
  end
end
