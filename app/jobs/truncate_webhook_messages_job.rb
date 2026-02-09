# typed: true
# frozen_string_literal: true

class TruncateWebhookMessagesJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: :global, on_conflict: :discard

  # == Job ==

  sig { void }
  def perform
    cutoff = WebhookMessage.order(timestamp: :desc).offset(500).pick(:timestamp)
    if cutoff
      WebhookMessage.where(timestamp: ...cutoff).delete_all
    end
  end
end
