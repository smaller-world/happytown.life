# typed: true
# frozen_string_literal: true

require "rails"
require "httparty"

class WaSenderApi
  extend T::Sig

  include HTTParty

  # == Exceptions ==

  class Error < StandardError
    extend T::Sig

    sig { params(response: HTTParty::Response).void }
    def initialize(response)
      @response = response
      super("WASenderAPI error (status #{response.code}): #{response.parsed_response}")
    end

    sig { returns(HTTParty::Response) }
    attr_reader :response
  end

  class TooManyRequests < Error; end

  # == Configuration ==

  ACCOUNT_PROTECTION_INTERVAL = 5

  base_uri "https://www.wasenderapi.com/api"
  format :json
  logger Rails.logger, Rails.configuration.log_level
  debug_output Rails.logger.debug if Rails.env.development?

  sig { params(api_key: String).void }
  def initialize(api_key:)
    self.class.headers("Authorization" => "Bearer #{api_key}")
    @message_last_sent_at = T.let(nil, T.nilable(ActiveSupport::TimeWithZone))
  end

  # == Methods ==

  sig { params(to: String, text: String, mentioned_jids: T.nilable(T::Array[String])).void }
  def send_message(to:, text:, mentioned_jids: nil)
    unless perform_deliveries?
      tag_logger do
        logger.info("Skipping message delivery to #{to}: #{text}")
      end
      return
    end

    wait_for_account_protection_period
    body = { to:, text:, mentions: mentioned_jids }.compact_blank
    response = self.class.post("/send-message", body:)
    check_response!(response)
    @message_last_sent_at = Time.current
  end

  sig { params(to: String, image_url: String, text: T.nilable(String)).void }
  def send_image_message(to:, image_url:, text: nil)
    unless perform_deliveries?
      tag_logger do
        logger.info("Skipping image message delivery to #{to}: #{image_url}")
      end
      return
    end

    wait_for_account_protection_period
    body = { to:, text:, "imageUrl" => image_url }.compact
    response = self.class.post("/send-message", body:)
    check_response!(response)
    @message_last_sent_at = Time.current
  end

  sig { params(to: String, video_url: String, text: T.nilable(String)).void }
  def send_video_message(to:, video_url:, text: nil)
    unless perform_deliveries?
      tag_logger do
        logger.info("Skipping video message delivery to #{to}: #{video_url}")
      end
      return
    end

    wait_for_account_protection_period
    body = { to:, text:, "videoUrl" => video_url }.compact
    response = self.class.post("/send-message", body:)
    check_response!(response)
    @message_last_sent_at = Time.current
  end

  sig { params(jid: String, type: String).void }
  def update_presence(jid:, type:)
    unless perform_deliveries?
      tag_logger do
        logger.info("Skipping presence update for #{jid}: #{type}")
      end
      return
    end

    body = { jid:, type: }
    response = self.class.post("/send-presence-update", body:)
    check_response!(response)
  end

  sig { params(jid: String).returns(T::Hash[String, T.untyped]) }
  def group_metadata(jid:)
    response = self.class.get("/groups/#{jid}/metadata")
    response_data!(response)
  end

  sig { params(jid: String).returns(T.nilable(String)) }
  def group_profile_picture_url(jid:)
    response = self.class.get("/groups/#{jid}/picture")
    if response.code == 422
      nil
    else
      response_data!(response).fetch("imgUrl")
    end
  end

  sig { params(jid: String).returns(T::Array[T::Hash[String, T.untyped]]) }
  def group_participants(jid:)
    response = self.class.get("/groups/#{jid}/participants")
    response_data!(response)
  end

  sig { params(lid: String).returns(String) }
  def phone_number_jid_for_user(lid:)
    response = self.class.get("/pn-from-lid/#{lid}")
    response_data!(response).fetch("pn")
  end

  sig { params(phone_number: String).returns(T.nilable(String)) }
  def contact_profile_picture_url(phone_number:)
    response = self.class.get("/contacts/#{phone_number}/picture")
    if response.code == 422
      nil
    else
      response_data!(response).fetch("imgUrl")
    end
  end

  private

  # == Helpers ==

  sig { params(response: HTTParty::Response).void }
  def check_response!(response)
    unless response.success?
      case response.code
      when 429
        raise TooManyRequests, response
      else
        raise Error, response
      end
    end
  end

  sig { params(response: HTTParty::Response).returns(T.untyped) }
  def response_data!(response)
    check_response!(response)
    response.parsed_response.fetch("data")
  end

  sig { returns(T::Boolean) }
  def perform_deliveries?
    Rails.configuration.x.perform_whatsapp_deliveries
  end

  sig { params(block: T.proc.void).void }
  def tag_logger(&block)
    logger = Rails.logger
    if logger.respond_to?(:tagged)
      args = [:tagged, "WaSenderApi"]
      logger.public_send(*T.unsafe(args), &block)
    else
      yield
    end
  end

  sig { returns(T.any(ActiveSupport::Logger, ActiveSupport::BroadcastLogger)) }
  def logger = Rails.logger

  sig { void }
  def wait_for_account_protection_period
    if @message_last_sent_at
      time_since_last_sent = Time.current - @message_last_sent_at
      if time_since_last_sent < ACCOUNT_PROTECTION_INTERVAL
        duration = ACCOUNT_PROTECTION_INTERVAL - time_since_last_sent
        tag_logger do
          logger.info("Waiting #{duration} seconds for account protection...")
        end
        sleep(duration)
      end
    end
  end
end
