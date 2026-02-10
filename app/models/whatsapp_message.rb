# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_messages
#
#  id                     :uuid             not null, primary key
#  body                   :text             not null
#  handled_at             :timestamptz
#  mentioned_jids         :string           default([]), not null, is an Array
#  quoted_conversation    :text
#  quoted_participant_jid :string
#  timestamp              :timestamptz      not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  group_id               :uuid             not null
#  message_id             :string           not null
#  quoted_message_id      :uuid
#  sender_id              :uuid             not null
#
# Indexes
#
#  index_whatsapp_messages_on_group_id           (group_id)
#  index_whatsapp_messages_on_handled_at         (handled_at)
#  index_whatsapp_messages_on_quoted_message_id  (quoted_message_id)
#  index_whatsapp_messages_on_sender_id          (sender_id)
#  index_whatsapp_messages_on_timestamp          (timestamp)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => whatsapp_groups.id)
#  fk_rails_...  (quoted_message_id => whatsapp_messages.id)
#  fk_rails_...  (sender_id => whatsapp_users.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappMessage < ApplicationRecord
  # == Associations ==

  belongs_to :group, class_name: "WhatsappGroup", inverse_of: :messages
  belongs_to :sender, class_name: "WhatsappUser"

  has_one :quoted_message, class_name: "WhatsappMessage", dependent: :nullify
  has_one :quoted_user, class_name: "WhatsappUser", dependent: :nullify

  has_many :mentions,
           class_name: "WhatsappMessageMention",
           dependent: :destroy,
           inverse_of: :message,
           foreign_key: :message_id
  has_many :mentioned_users, through: :mentions

  sig { returns(WhatsappGroup) }
  def group!
    group or raise ActiveRecord::RecordNotFound, "Missing associated group"
  end

  sig { returns(WhatsappUser) }
  def sender!
    sender or raise ActiveRecord::RecordNotFound, "Missing sender"
  end

  # == Hooks ==

  after_create_commit :handle, if: :requires_handling?

  # == Handling ==

  scope :requires_handling, -> {
    application_jid = Rails.configuration.x.whatsapp_jid
    sender_id = WhatsappUser.where(lid: application_jid).select(:id)
    where(handled_at: nil).where.not(sender_id:)
      .and(
        where(quoted_participant_jid: application_jid).or(
          where("? = ANY(mentioned_jids)", application_jid),
        ),
      )
  }

  sig { returns(T::Boolean) }
  def handled? = handled_at?

  sig { returns(T::Boolean) }
  def requires_handling?
    application_jid = Rails.configuration.x.whatsapp_jid
    !from_application? && (
      quoted_participant_jid == application_jid ||
        mentioned_jids.include?(application_jid)
    )
  end

  sig { void }
  def handle
    reply unless handled?
  end

  # == Replying ==

  sig { returns(ActiveAgent::Generation) }
  def reply_prompt
    WhatsappGroupAgent.with(group: group!, message: self).reply
  end

  sig { void }
  def reply
    reply_prompt.generate_now
    update!(handled_at: Time.current)
  end

  # == Methods

  sig { returns(String) }
  def application_jid
    Rails.configuration.x.whatsapp_jid
  end

  sig { returns(T::Boolean) }
  def from_application?
    sender&.lid == application_jid
  end

  # == Helpers ==

  sig do
    params(payload: T::Hash[String, T.untyped])
      .returns(T.nilable(WhatsappMessage))
  end
  def self.from_webhook_payload(payload)
    event = payload.fetch("event")
    case event
    when "messages.upsert"
      messages = payload.dig("data", "messages") or return
      return if messages.dig("message", "reactionMessage").present?
      return if messages.dig("messageBody").nil?

      user = WhatsappUser.from_webhook_payload(payload) or return
      remote_jid = messages.fetch("remoteJid")
      group = WhatsappGroup.find_or_initialize_by(jid: remote_jid)

      if (context_info = messages.dig(
        "message",
        "extendedTextMessage",
        "contextInfo",
      ))
        mentioned_jids = context_info.fetch("mentionedJid") { [] }
        quoted_conversation = context_info.dig("quotedMessage", "conversation")
        if quoted_conversation
          quoted_participant_jid = context_info.fetch("participant")
          stanza_id = context_info.fetch("stanzaId")
          quoted_message = WhatsappMessage.find_by(message_id: stanza_id)
        end
      end

      message_id = messages.fetch("id")
      body = messages.fetch("messageBody")
      raw_timestamp = messages.fetch("messageTimestamp")
      WhatsappMessage.find_or_initialize_by(message_id:) do |message|
        message.group = group
        message.sender = user
        message.timestamp = Time.zone.at(raw_timestamp / 1000.0)
        message.body = body
        message.quoted_conversation = quoted_conversation
        message.quoted_participant_jid = quoted_participant_jid
        message.quoted_message = quoted_message
        if mentioned_jids
          message.mentioned_jids = mentioned_jids
          message.mentioned_users =
            WhatsappUser.from_mentioned_jids(mentioned_jids)
        end
      end
    end
  end
end
