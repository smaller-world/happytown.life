# typed: true
# frozen_string_literal: true

class ForwardWebhookMessageToDevServerJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  discard_on OpenSSL::SSL::SSLError

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
    if response.success?
      Rails.logger.info("Forwarded webhook message to dev server")
    elsif response.code == 530
      Rails.logger.debug("Dev server is offline")
    else
      raise "Failed to forward webhook message (status: #{response.code}): " \
        "#{response.parsed_response}"
    end
  end
end
