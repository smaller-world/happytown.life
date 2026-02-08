# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_groups
#
#  id                   :uuid             not null, primary key
#  description          :text
#  jid                  :string           not null
#  metadata_imported_at :timestamptz
#  subject              :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_whatsapp_groups_on_jid                   (jid) UNIQUE
#  index_whatsapp_groups_on_metadata_imported_at  (metadata_imported_at)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappGroup < ApplicationRecord
  # == Hooks ==

  # after_create_commit :send_welcome_message_later
  after_create_commit :import_metadata_later

  # == Metadata ==

  sig { void }
  def import_metadata
    data = HappyTown.application.wa_sender_api.get_group_metadata(jid:)
    update!(
      subject: data["subject"],
      description: data["desc"],
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

  sig { params(text: String).void }
  def send_message(text)
    HappyTown.application.wa_sender_api.send_message(to: jid, text:)
  end

  sig do
    params(text: String, options: T.untyped)
      .returns(T.any(SendWhatsappGroupMessageJob, FalseClass))
  end
  def send_message_later(text, **options)
    SendWhatsappGroupMessageJob.set(**options).perform_later(self, text)
  end

  private

  # == Helpers ==

  sig { void }
  def send_welcome_message_later
    send_message_later(welcome_message, wait: 4.seconds)
  end

  sig { returns(String) }
  def welcome_message
    raise NotImplementedError
  end
end
