module Kracken
  KrackenError        = Class.new(StandardError)
  RequestError        = Class.new(KrackenError)
  MissingUIDError     = Class.new(KrackenError)

  module Controllers
    UnprocessableEntity = Class.new(StandardError)

    class TokenUnauthorized < KrackenError
      def initialize(msg = nil)
        msg ||= 'HTTP Token: Access denied.'
        super(msg)
      end
    end

    class ResourceNotFound < KrackenError
      attr_reader :missing_ids, :resource
      def initialize(resource, missing_ids)
        @missing_ids = Array(missing_ids)
        @resource    = resource
        super(
          "Couldn't find #{resource} with id(s): #{missing_ids.join(', ')}"
        )
      end
    end
  end
end
