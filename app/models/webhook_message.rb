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
#  event_id   :string           not null
#
# Indexes
#
#  index_webhook_messages_on_timestamp  (timestamp)
#  index_webhook_messages_uniqueness    (event,event_id) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WebhookMessage < ApplicationRecord
  # == Validations ==

  validates :timestamp, presence: true
  validates :event_id, presence: true, uniqueness: { scope: :event }
  validates :data, presence: true

  # == Helpers ==

  sig { params(payload: T::Hash[String, T.untyped]).returns(WebhookMessage) }
  def self.from_webhook_payload(payload)
    event = payload.fetch("event")
    timestamp = Time.zone.at(payload.fetch("timestamp") / 1000.0)
    data = payload.fetch("data")
    event_id = case event
    when "messages-group.received"
      data.dig("messages", "id")
    when "message.sent"
      data.dig("key", "id")
    end
    WebhookMessage.find_or_create_by!(event:, event_id:) do |message|
      message.timestamp = timestamp
      message.data = data
    end
  end
end
