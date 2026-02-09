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
#  memberships_imported_at           :timestamptz
#  metadata_imported_at              :timestamptz
#  profile_picture_url               :string
#  record_full_message_history_since :timestamptz
#  subject                           :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_whatsapp_groups_on_jid                      (jid) UNIQUE
#  index_whatsapp_groups_on_memberships_imported_at  (memberships_imported_at)
#  index_whatsapp_groups_on_metadata_imported_at     (metadata_imported_at)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappGroup < ApplicationRecord
  # == Associations ==

  has_many :messages,
           class_name: "WhatsappMessage",
           dependent: :destroy,
           inverse_of: :group,
           foreign_key: :group_id
  has_many :memberships,
           class_name: "WhatsappGroupMembership",
           dependent: :destroy,
           inverse_of: :group,
           foreign_key: :group_id

  # == Hooks ==

  after_create_commit :introduce_yourself
  after_create_commit :import_metadata_later
  after_create_commit :import_memberships_later

  # == Metadata ==

  sig { void }
  def import_metadata
    metadata = wa_sender_api.group_metadata(id)
    profile_picture_url = if (data = wa_sender_api.group_profile_picture(id))
      data.fetch("imgUrl")
    end
    update!(
      subject: metadata["subject"],
      description: metadata["desc"],
      profile_picture_url:,
      metadata_imported_at: Time.current,
    )
  end

  sig do
    params(options: T.untyped)
      .returns(T.any(ImportWhatsappGroupMetadataJob, FalseClass))
  end
  def import_metadata_later(**options)
    ImportWhatsappGroupMetadataJob
      .set(**options)
      .perform_later(self)
  end

  # == Memberships ==

  sig { void }
  def import_memberships
    participants = wa_sender_api.group_participants(id)
    self.memberships = participants.map do |data|
      user = WhatsappUser.find_or_initialize_by(lid: data.fetch("id"))
      WhatsappGroupMembership.new(user:, admin: data["admin"])
    end
  end

  sig do
    params(options: T.untyped)
      .returns(T.any(ImportWhatsappGroupMembershipsJob, FalseClass))
  end
  def import_memberships_later(**options)
    ImportWhatsappGroupMembershipsJob
      .set(**options)
      .perform_later(self)
  end

  # == Messaging ==

  sig { params(text: String, reply_to: T.nilable(String)).void }
  def send_message(text, reply_to: nil)
    wa_sender_api.send_message(to: id, text:, reply_to:)
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

  sig { params(block: T.proc.void).void }
  def indicate_typing_while(&block)
    wa_sender_api.update_presence(jid:, type: "composing")
    yield
  ensure
    wa_sender_api.update_presence(jid:, type: "available")
  end

  sig { returns(ActiveAgent::Generation) }
  def introduce_yourself_prompt
    WhatsappGroupAgent.with(group: self).introduce_yourself
  end

  sig { void }
  def introduce_yourself
    introduce_yourself_prompt.generate_now
  end

  private

  # == Helpers ==

  sig { returns(WaSenderApi) }
  def wa_sender_api
    HappyTown.application.wa_sender_api
  end
end
