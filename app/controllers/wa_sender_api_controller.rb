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
    unless payload["event"] == "messages-group.received"
      head(:ok) and return
    end

    save_webhook_message(payload)
    whatsapp_group = create_whatsapp_group(payload)

    if should_reply?(payload)
      response = generate_response(payload)
      whatsapp_group.send_message_later(response)
    end

    head(:ok)
  end

  private

  # == Helpers ==

  sig { params(payload: T::Hash[String, T.untyped]).returns(T::Boolean) }
  def should_reply?(payload)
    context_info = payload.dig(
      "data",
      "messages",
      "message",
      "extendedTextMessage",
      "contextInfo",
    ) or return false
    if (jids = context_info["mentionedJid"])
      jids.include?(whatsapp_jid)
    else
      context_info["participant"] == whatsapp_jid
    end
  end

  sig { params(payload: T::Hash[String, T.untyped]).void }
  def save_webhook_message(payload)
    data = payload.fetch("data")
    messages_id = data.dig("messages", "id")
    WebhookMessage.find_or_create_by!(messages_id:) do |message|
      message.timestamp = Time.zone.at(payload.fetch("timestamp") / 1000.0)
      message.data = data
    end
  end

  sig { params(payload: T::Hash[String, T.untyped]).returns(WhatsappGroup) }
  def create_whatsapp_group(payload)
    jid = payload.dig("data", "messages", "remoteJid")
    WhatsappGroup.find_or_create_by!(jid:)
  end

  sig { params(payload: T::Hash[String, T.untyped]).returns(String) }
  def generate_response(payload)
    messages = payload.dig("data", "messages")
    message, sender_name = messages.values_at("messageBody", "pushName")
    context_message = if (conversation = messages.dig(
      "message",
      "extendedTextMessage",
      "contextInfo",
      "quotedMessage",
      "conversation",
    ))
      "'#{sender_name}' replied to your whatsapp message:\n\n" \
        "\"\"\"#{conversation}\"\"\""
    else
      "'#{sender_name}' mentioned you in a whatsapp message (your whatsapp " \
        "JID is: #{whatsapp_jid})."
    end
    system_message = "#{context_message}\n\n" \
      "there is no more context available, yolo a response. please respond " \
      "in all lowercase!!! (except for confusable terms like 'JID')"
    HappyTown.application.open_router.complete_chat([
      { role: "system", content: system_message },
      { role: "user", content: message },
    ])
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
