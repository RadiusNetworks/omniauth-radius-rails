# frozen_string_literal: true

module Kracken
  module JsonApi
    module RoutingMapper
      module_function def json_api(path, options = {})
        (options[:defaults] ||= {}).reverse_merge!(format: :json)
        namespace path, options do
          JsonApi.add_path(@scope[:path])
          yield
        end
      end
    end
  end
end
ActionDispatch::Routing::Mapper.include Kracken::JsonApi::RoutingMapper
