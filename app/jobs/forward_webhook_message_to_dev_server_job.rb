# typed: true
# frozen_string_literal: true

class ForwardWebhookMessageToDevServerJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  discard_on OpenSSL::SSL::SSLError

  # == Job ==

  sig { params(body: String, webhook_signature: String).void }
  def perform(body:, webhook_signature:)
    webhook_url = webhook_url(
      **Rails.configuration.x.webhook_forwarding.dev_server_url_options,
    )
    response = HTTP.post(webhook_url, body: body, headers: {
      "X-Webhook-Signature" => webhook_signature,
    })
    if response.status.success?
      logger.info("Forwarded webhook message to dev server")
    elsif response.code.in?([ 530, 502 ])
      logger.debug("Dev server is offline")
    else
      raise "Failed to forward webhook message (status: #{response.code}): " \
        "#{response.parse}"
    end
  end
end
