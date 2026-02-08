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

    messages = T.let(
      payload.dig("data", "messages"),
      T::Hash[String, T.untyped],
    )
    jid = T.let(messages.fetch("remoteJid"), String)
    group = WhatsappGroup.find_or_create_by!(jid:)

    if should_reply?(messages:)
      response = generate_response(messages:)
      group.send_message_later(response)
    end

    head(:ok)
  end

  private

  # == Helpers ==

  def should_reply?(messages:)
    context_info = messages.dig(
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

  sig { params(messages: T::Hash[String, T.untyped]).returns(String) }
  def generate_response(messages:)
    message = messages.fetch("messageBody")
    sender_name = messages.fetch("pushName")
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
