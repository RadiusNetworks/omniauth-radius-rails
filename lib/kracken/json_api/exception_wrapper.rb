module Kracken
  module JsonApi
    class ExceptionWrapper < ActionDispatch::ExceptionWrapper
      cattr_accessor :rescue_with_details_responses
      @@rescue_with_details_responses = Hash.new
      @@rescue_with_details_responses.merge!(
        'Kracken::ResourceNotFound' => :not_found,
        'Kracken::TokenUnauthorized' => :unauthorized,
        'Kracken::UnprocessableEntity' => :unprocessable_entity,
      )

      def self.status_code_for_exception(class_name)
        if @@rescue_with_details_responses.has_key?(class_name)
          Rack::Utils.status_code(@@rescue_with_details_responses[class_name])
        else
          Rack::Utils.status_code(@@rescue_responses[class_name])
        end
      end

      def is_details_exception?
        @@rescue_with_details_responses.has_key?(exception.class.name)
      end
    end
  end
end