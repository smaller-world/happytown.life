# typed: true
# frozen_string_literal: true

class WaSenderApi
  extend T::Sig
  include HTTParty

  # == Configuration ==

  base_uri "https://www.wasenderapi.com/api"
  format :json

  sig { params(api_key: String).void }
  def initialize(api_key:)
    self.class.headers("Authorization" => "Bearer #{api_key}")
  end

  # == Methods ==

  sig { params(to: String, text: String, reply_to: T.nilable(String)).void }
  def send_message(to:, text:, reply_to: nil)
    body = { to:, text:, "replyTo" => reply_to }.compact
    response = self.class.post("/send-message", body:)
    unless response.success?
      raise "WASenderAPI error (#{response.code}): #{response.parsed_response}"
    end
  end

  sig { params(jid: String, type: String, delay_ms: T.nilable(Integer)).void }
  def update_presence(jid:, type:, delay_ms: nil)
    body = { jid:, type:, "delayMs" => delay_ms }.compact
    response = self.class.post("/send-presence-update", body:)
    unless response.success?
      raise "WASenderAPI error (#{response.code}): #{response.parsed_response}"
    end
  end

  sig { params(jid: String).returns(T::Hash[String, T.untyped]) }
  def group_metadata(jid)
    response = self.class.get("/groups/#{jid}/metadata")
    response_data!(response)
  end

  sig { params(jid: String).returns(T::Array[T::Hash[String, T.untyped]]) }
  def group_participants(jid)
    response = self.class.get("/groups/#{jid}/participants")
    response_data!(response)
  end

  sig { params(jid: String).returns(T.nilable(T::Hash[String, T.untyped])) }
  def group_profile_picture(jid)
    response = self.class.get("/groups/#{jid}/picture")
    if response.code == 422
      nil
    else
      response_data!(response)
    end
  end

  private

  # == Helpers ==

  sig { params(response: HTTParty::Response).returns(T.untyped) }
  def response_data!(response)
    unless response.success?
      raise "WASenderAPI error (#{response.code}): #{response.parsed_response}"
    end

    response.parsed_response.fetch("data")
  end
end
