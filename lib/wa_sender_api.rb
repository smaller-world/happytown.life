# typed: true
# frozen_string_literal: true

class WaSenderApi
  extend T::Sig
  include HTTParty

  # == Configuration ==

  base_uri "https://www.wasenderapi.com/api"
  format :json

  # == Initializer ==

  sig { params(api_key: String).void }
  def initialize(api_key:)
    self.class.headers("Authorization" => "Bearer #{api_key}")
  end

  # == Methods ==

  sig { params(to: String, text: String).void }
  def send_message(to:, text:)
    response = self.class.post("/send-message", body: { to:, text: })
    unless response.success?
      raise "WASenderAPI error (#{response.code}): #{response.parsed_response}"
    end
  end
end
