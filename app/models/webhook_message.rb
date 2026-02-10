# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: webhook_messages
#
#  id         :uuid             not null, primary key
#  data       :jsonb            not null
#  event      :string           not null
#  timestamp  :timestamptz      not null
#  created_at :timestamptz      not null
#
# Indexes
#
#  index_webhook_messages_on_timestamp  (timestamp)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WebhookMessage < ApplicationRecord
  # == Validations ==

  validates :timestamp, presence: true
  validates :data, presence: true

  # == Helpers ==

  sig { params(payload: T::Hash[String, T.untyped]).returns(WebhookMessage) }
  def self.create_from_webhook_payload!(payload)
    event = payload.fetch("event")
    timestamp = Time.zone.at(payload.fetch("timestamp") / 1000.0)
    data = payload.fetch("data")
    WebhookMessage.create!(event:, timestamp:, data:)
  end
end
