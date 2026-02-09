# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_groups
#
#  id                                :uuid             not null, primary key
#  description                       :text
#  jid                               :string           not null
#  metadata_imported_at              :timestamptz
#  profile_picture_url               :string
#  record_full_message_history_since :timestamptz
#  subject                           :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_whatsapp_groups_on_jid                   (jid) UNIQUE
#  index_whatsapp_groups_on_metadata_imported_at  (metadata_imported_at)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappGroup < ApplicationRecord
  # == Associations ==

  has_many :messages,
           class_name: "WhatsappMessage",
           dependent: :destroy,
           inverse_of: :group,
           foreign_key: :group_id

  # == Hooks ==

  after_create_commit :introduce_yourself
  after_create_commit :import_metadata_later

  # == Metadata ==

  sig { void }
  def import_metadata
    api = HappyTown.application.wa_sender_api
    data = api.group_metadata(jid)
    profile_picture_url = api.group_profile_picture_url(jid)
    update!(
      subject: data["subject"],
      description: data["desc"],
      profile_picture_url:,
      metadata_imported_at: Time.current,
    )
  end

  sig do
    params(options: T.untyped)
      .returns(T.any(ImportWhatsappGroupMetadataJob, FalseClass))
  end
  def import_metadata_later(**options)
    ImportWhatsappGroupMetadataJob.set(**options).perform_later(self)
  end

  # == Messaging ==

  sig { params(text: String, reply_to: T.nilable(String)).void }
  def send_message(text, reply_to: nil)
    HappyTown.application.wa_sender_api.send_message(to: jid, text:, reply_to:)
  end

  sig do
    params(text: String, reply_to: T.nilable(String), options: T.untyped)
      .returns(T.any(SendWhatsappGroupMessageJob, FalseClass))
  end
  def send_message_later(text, reply_to: nil, **options)
    SendWhatsappGroupMessageJob
      .set(**options)
      .perform_later(self, text, reply_to:)
  end

  sig { returns(ActiveAgent::Generation) }
  def introduce_yourself_prompt
    WhatsappGroupAgent.with(group: self).introduce_yourself
  end

  sig { void }
  def introduce_yourself
    introduce_yourself_prompt.generate_now
  end

  # == Helpers ==

  # sig do
  #   params(payload: T::Hash[String, T.untyped])
  #     .returns(T.nilable(WhatsappGroup))
  # end
  # def self.from_webhook_payload(payload)
  #   event = payload.fetch("event")
  #   case event
  #   when "messages-group.received"
  #     jid = payload.dig("data", "messages", "remoteJid")
  #     WhatsappGroup.find_or_initialize_by(jid:)
  #   end
  # end
end
