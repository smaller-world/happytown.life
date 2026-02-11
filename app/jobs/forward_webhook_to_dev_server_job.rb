# typed: true
# frozen_string_literal: true

class ForwardWebhookToDevServerJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def default_url_options
    ActionMailer::Base.default_url_options
  end

  # == Job ==

  sig { params(body: String, webhook_signature: String).void }
  def perform(body:, webhook_signature:)
    response = HTTParty.post(webhook_url, body: body, headers: {
      "X-Webhook-Signature" => webhook_signature,
    })
    Rails.logger.info(
      "Forwarded webhook message to dev server (status: #{response.code})",
    )
  end
end
