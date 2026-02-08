# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_groups
#
#  id          :uuid             not null, primary key
#  description :text
#  jid         :string           not null
#  subject     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_whatsapp_groups_on_jid  (jid) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappGroup < ApplicationRecord
  # == Hooks ==

  after_create_commit :send_welcome_message_later

  # == Messaging ==

  sig { params(text: String).void }
  def send_message(text)
    response = HTTParty.post(
      "https://www.wasenderapi.com/api/send-message",
      body: { to: jid, text: text },
      headers: {
        "Authorization" => "Bearer #{wasenderapi_key}",
        "Content-Type" => "application/json",
      },
    )
    unless response.success?
      raise "WASenderAPI error (#{response.code}): #{response.parsed_response}"
    end
  end

  sig do
    params(text: String).returns(T.any(WhatsappGroupSendMessageJob, FalseClass))
  end
  def send_message_later(text)
    WhatsappGroupSendMessageJob.perform_later(self, text)
  end

  private

  # == Helpers ==

  sig { void }
  def send_welcome_message_later
    # send_message_later("welcome to happy town :) [jid=#{jid}]")
    send_message("welcome to happy town :) [jid=#{jid}]")
  end

  sig { returns(String) }
  def wasenderapi_key
    Rails.application.credentials.dig(:wasenderapi, :api_key) or
      raise "Missing WASenderAPI key"
  end
end
