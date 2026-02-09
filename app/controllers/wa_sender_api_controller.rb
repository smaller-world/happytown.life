# typed: true
# frozen_string_literal: true

class WaSenderApiController < ApplicationController
  # == Configuration ==

  allow_unauthenticated_access
  skip_forgery_protection

  # == Filters ==

  before_action :verify_webhook_signature!

  # == Actions ==

  sig { void }
  def webhook
    payload = JSON.parse(request.raw_post)
    event = payload.fetch("event")
    case event
    when "messages-group.received"
      save_webhook_message(payload)
      if (message = WhatsappMessage.from_webhook_payload(payload))
        message.save!
      end
    when "message.sent"
    end
    head(:ok)
  end

  private

  # == Helpers ==

  sig { params(payload: T::Hash[String, T.untyped]).void }
  def save_webhook_message(payload)
    event = payload.fetch("event")
    data = payload.fetch("data")
    event_id = data.dig("messages", "key", "id")
    WebhookMessage.find_or_create_by!(event:, event_id:) do |message|
      message.timestamp = Time.zone.at(payload.fetch("timestamp") / 1000.0)
      message.data = data
    end
  end

  sig { void }
  def verify_webhook_signature!
    signature = request.headers["X-Webhook-Signature"]
    secret = webhook_secret

    unless ActiveSupport::SecurityUtils
        .secure_compare(signature.to_s, secret.to_s)
      head(:unauthorized)
    end
  end

  sig { returns(String) }
  def webhook_secret
    Rails.application.credentials.dig(:wa_sender_api, :webhook_secret) or
      raise "Missing WASenderAPI webhook secret"
  end

  sig { returns(String) }
  def whatsapp_jid
    Rails.configuration.x.whatsapp_jid or raise "Missing WhatsApp JID"
  end
end
