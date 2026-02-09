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

    # Log webhook message
    webhook_message = WebhookMessage.from_webhook_payload(payload)
    webhook_message.save!

    # Handle event
    case event
    when "message.upsert"
      if (message = WhatsappMessage.from_webhook_payload(payload))
        message.save!
      end
    when "group-participants.update"
      data = payload.fetch("data")
      if (group = WhatsappGroup.find_by(jid: data.fetch("jid")))
        group.import_memberships_later
      end
    end
    head(:ok)
  end

  private

  # == Helpers ==

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
