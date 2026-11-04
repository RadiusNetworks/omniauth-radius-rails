# frozen_string_literal: true

module Kracken
  module JsonApi
    class ExceptionWrapper < ActionDispatch::ExceptionWrapper
      # Rack 3.1 renamed `:unprocessable_entity` to `:unprocessable_content`
      # and deprecated the old spelling, which now warns on every use. Rails
      # papers over this with `ActionDispatch::Response.rack_status_code`, but
      # only from 7.2, and we still support 7.1.
      UNPROCESSABLE =
        if Rack::Utils::SYMBOL_TO_STATUS_CODE.key?(:unprocessable_content)
          :unprocessable_content
        else
          :unprocessable_entity
        end

      cattr_accessor :rescue_with_details_responses, default: {
        'Kracken::ResourceNotFound' => :not_found,
        'Kracken::TokenUnauthorized' => :unauthorized,
        'Kracken::UnprocessableEntity' => UNPROCESSABLE,
      }

      def self.status_code_for_exception(class_name)
        status = rescue_with_details_responses.fetch(class_name) {
          rescue_responses[class_name]
        }
        Rack::Utils.status_code(status)
      end

      attr_reader :raised_exception

      def initialize(backtrace_cleaner, exception)
        super
        @raised_exception = exception
      end

      def is_details_exception?
        rescue_with_details_responses.key?(raised_exception.class.name) ||
          rescue_with_details_responses.key?(exception.class.name)
      end
    end
  end
end
