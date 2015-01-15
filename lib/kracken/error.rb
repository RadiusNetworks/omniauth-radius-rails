module Kracken
  KrackenError = Class.new(StandardError)
  RequestError = Class.new(KrackenError)
  MissingUIDError = Class.new(KrackenError)
end
