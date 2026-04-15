# typed: true
# frozen_string_literal: true

module WaSenderApi
  extend T::Sig
  include TaggedLogging

  # == Exceptions ==

  class Error < StandardError; end

  class BadResponse < StandardError
    extend T::Sig

    sig { params(response: HTTP::Response).void }
    def initialize(response)
      @response = response
      super("WASenderAPI error (status #{response.code}): #{response.parse}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response
  end

  class TooManyRequests < BadResponse; end
  class RequestTimeout < BadResponse; end
  class Forbidden < BadResponse; end

  # == Configuration ==

  ACCOUNT_PROTECTION_INTERVAL = 5
end
