# typed: true
# frozen_string_literal: true

class ForwardWebhookToDevServerJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { params(body: String, webhook_signature: String).void }
  def perform(body:, webhook_signature:)
    response = HTTParty.post(target_url, body: body, headers: {
      "X-Webhook-Signature" => webhook_signature,
    })
    Rails.logger.info(
      "Forwarded webhook message to dev server (status: #{response.code})",
    )
  end

  private

  # == Helpers ==

  sig { returns(String) }
  def target_url
    Rails.application.routes.url_helpers.webhook_url(
      **Rails.configuration.x.dev_server_url_options,
    )
  end
end
