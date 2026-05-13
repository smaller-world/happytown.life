# typed: true
# frozen_string_literal: true

class WsapiController < ApplicationController
  # == Configuration ==

  allow_unauthenticated_access
  skip_forgery_protection

  # == Filters ==

  before_action :verify_webhook_signature!
  # after_action :forward_webhook_message_to_dev_server if Rails.env.production?

  # == Actions ==

  # POST /wsapi/webhook
  sig { void }
  def webhook
    event_type = params.fetch("eventType")
    event_data = params.fetch("eventData").to_unsafe_h

    # Handle event
    case event_type
    when "message"
      message = WsapiMessage.from_event_data(event_data)
      Rails.cache.fetch("wsapi/webhook/message/#{message.id}", expires_in: 1.minute) do
        screen_message(message)
        true
      end
    end
    head(:ok)
  end

  private

  # == Helpers ==

  sig { params(message: WsapiMessage).returns(T.untyped) }
  def screen_message(message)
    return unless scam_message?(message)

    tag_logger do
      logger.info("Message from #{message.sender.id} failed screening: #{message.text}")
    end

    if (community_id = wsapi.community_id(group_id: message.chat_id))
      is_admin = wsapi.community_admin?(community_id:, participant_id: message.sender.id)
      if is_admin
        wsapi.send_message(to: message.chat_id, text: "👀")
      else
        delete_message(message)
        wsapi.remove_community_participants(
          community_id:,
          participant_ids: [ message.sender.id ],
        )
      end
    else
      is_admin = wsapi.group_admin?(
        group_id: message.chat_id,
        participant_id: message.sender.id,
      )
      if is_admin
        wsapi.send_message(to: message.chat_id, text: "👀")
      else
        delete_message(message)
        wsapi.remove_group_participants(
          group_id: message.chat_id,
          participant_ids: [ message.sender.id ],
        )
      end
    end
  end

  sig { params(message: WsapiMessage).returns(T::Boolean) }
  def scam_message?(message)
    return false unless message.is_group

    text = message.text.downcase
    text.include?("investment") && message.text.include?("https://chat.whatsapp.com")
  end

  sig { params(message: WsapiMessage).void }
  def delete_message(message)
    wsapi.delete_message(
      message_id: message.id,
      chat_id: message.chat_id,
      sender_id: message.sender.id,
    )
  rescue Wsapi::BadResponse => error
    data = error.response.parse
    if (detail = data["detail"]) && detail.include?("403")
      logger.warn("Couldn't delete message (bad permissions): #{detail}")
      wsapi.send_message(
        to: message.chat_id,
        text: "Couldn't delete message from #{message.sender.phone} " \
          "(not group admin)",
      )
      nil
    end
  end

  sig { returns(String) }
  def webhook_signature!
    request.headers["X-Webhook-Signature"] or raise "Missing webhook signature"
  end

  sig { void }
  def verify_webhook_signature!
    signature = request.headers["X-Webhook-Signature"]
    return head(:unauthorized) if signature.blank?

    expected = "sha256=" +
      OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, request.raw_post)
    unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
      head(:unauthorized)
    end
  end

  sig { returns(String) }
  def webhook_secret
    Rails.application.credentials.wsapi.webhook_secret or
      raise "Missing WSAPI webhook secret"
  end

  sig { returns(Wsapi::Client) }
  def wsapi
    HappyTown.wsapi
  end

  # == Callbacks ==

  sig { void }
  def forward_webhook_message_to_dev_server
    ForwardWebhookMessageToDevServerJob.perform_later(
      body: request.raw_post,
      webhook_signature: webhook_signature!,
    )
  end
end
