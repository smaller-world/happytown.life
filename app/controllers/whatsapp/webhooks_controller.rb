# typed: true
# frozen_string_literal: true

module Whatsapp
  class WebhooksController < ApplicationController
    # == Configuration ==

    allow_unauthenticated_access
    skip_forgery_protection

    # == Filters ==

    before_action :verify_signature!

    # == Actions ==

    sig { void }
    def receive
      payload = JSON.parse(request.raw_post)
      unless payload["event"] == "messages-group.received"
        head(:ok) and return
      end

      jid = params.dig("data", "messages", "remoteJid")
      head(:bad_request) and return if jid.blank?

      WhatsappGroup.find_or_create_by!(jid:)

      head(:ok)
    end

    private

    # == Helpers ==
    #
    sig { void }
    def verify_signature!
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
  end
end
