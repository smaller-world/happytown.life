# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: webhook_messages
#
#  id          :uuid             not null, primary key
#  data        :jsonb            not null
#  timestamp   :timestamptz      not null
#  created_at  :timestamptz      not null
#  messages_id :string           not null
#
# Indexes
#
#  index_webhook_messages_on_messages_id  (messages_id) UNIQUE
#  index_webhook_messages_on_timestamp    (timestamp)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WebhookMessage < ApplicationRecord
  # == Validations ==

  validates :timestamp, presence: true
  validates :messages_id, presence: true, uniqueness: true
  validates :data, presence: true
end
