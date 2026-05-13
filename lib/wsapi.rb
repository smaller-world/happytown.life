# typed: true
# frozen_string_literal: true

module Wsapi
  extend T::Sig
  include TaggedLogging

  # == Exceptions ==

  class Error < StandardError; end

  class BadResponse < StandardError
    extend T::Sig

    sig { params(response: HTTP::Response).void }
    def initialize(response)
      @response = response
      super("WSAPI error (status #{response.code}): #{response.parse}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response
  end
end
