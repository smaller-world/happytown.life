# typed: true
# frozen_string_literal: true

class WaSenderApi
  extend T::Sig

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

  sig { params(api_key: String).void }
  def initialize(api_key:)
    @session = T.let(
      HTTP
        .use(logging: { logger: Rails.logger.tagged(self.class.name) })
        .base_uri("https://www.wasenderapi.com/api")
        .auth("Bearer #{api_key}"),
      HTTP::Session,
    )
    @message_last_sent_at = T.let(
      nil,
      T.nilable(ActiveSupport::TimeWithZone),
    )
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
    payload = { to:, text:, mentions: mentioned_jids }.compact_blank
    tag_logger do
      logger.debug("Sending message: #{payload}")
    end
    post!("/send-message", json: payload)
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
    payload = { to:, text:, "imageUrl" => image_url }.compact
    tag_logger do
      logger.debug("Sending image message: #{payload}")
    end
    post!("/send-message", json: payload)
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
    payload = { to:, text:, "videoUrl" => video_url }.compact
    tag_logger do
      logger.debug("Sending video message: #{payload}")
    end
    post!("/send-message", json: payload)
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

    payload = { jid:, type: }
    tag_logger do
      logger.debug("Sending presence update: #{payload}")
    end
    post!("/send-presence-update", json: payload)
  end

  sig { params(jid: String).returns(T::Hash[String, T.untyped]) }
  def group_metadata(jid:)
    get_data!("/groups/#{jid}/metadata")
  end

  sig { params(jid: String).returns(T.nilable(String)) }
  def group_profile_picture_url(jid:)
    response = @session.get("/groups/#{jid}/picture")
    if response.code == 422
      nil
    else
      response_data!(response).fetch("imgUrl")
    end
  end

  sig { params(jid: String).returns(T::Array[T::Hash[String, T.untyped]]) }
  def group_participants(jid:)
    get_data!("/groups/#{jid}/participants")
  end

  sig { params(lid: String).returns(T.nilable(String)) }
  def phone_number_jid_for_user(lid:)
    get_data!("/pn-from-lid/#{lid}").fetch("pn").presence
  end

  sig { params(phone_number: String).returns(T.nilable(String)) }
  def contact_profile_picture_url(phone_number:)
    response = @session.get("/contacts/#{phone_number}/picture")
    if response.code == 422
      nil
    else
      check_response!(response)
      response_data!(response).fetch("imgUrl")
    end
  end

  private

  # == Helpers ==

  sig { params(path: String, options: T.untyped).returns(T.untyped) }
  def get!(path, **options)
    response = @session.get(path, **options)
    check_response!(response)
    response.parse
  end

  sig { params(path: String, options: T.untyped).returns(T.untyped) }
  def get_data!(path, **options)
    response = @session.get(path, **options)
    check_response!(response)
    response_data!(response)
  end

  sig { params(path: String, options: T.untyped).returns(T.untyped) }
  def post!(path, **options)
    response = @session.post(path, **options)
    check_response!(response)
    response.parse
  end

  sig { params(response: HTTP::Response).void }
  def check_response!(response)
    unless response.status.success?
      case response.code
      when 408
        raise RequestTimeout, response
      when 422
        raise Forbidden, response
      when 429
        raise TooManyRequests, response
      else
        raise BadResponse, response
      end
    end
  end

  sig { params(response: HTTP::Response).returns(T.untyped) }
  def response_data!(response)
    parsed_response = response.parse
    if parsed_response["success"] == false
      message = parsed_response.fetch("message")
      raise Error, message
    end
    parsed_response["data"]
  end

  sig { returns(T::Boolean) }
  def perform_deliveries?
    Rails.configuration.x.whatsapp.perform_deliveries
  end

  sig { params(tags: String, block: T.proc.void).void }
  def tag_logger(*tags, &block)
    logger = Rails.logger
    if logger.respond_to?(:tagged)
      T.unsafe(logger).tagged(self.class.name, *tags, &block)
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
