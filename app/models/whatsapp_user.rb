# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_users
#
#  id               :uuid             not null, primary key
#  display_name     :string
#  lid              :string           not null
#  phone_number     :string
#  phone_number_jid :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_whatsapp_users_on_lid           (lid) UNIQUE
#  index_whatsapp_users_on_phone_number  (phone_number) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappUser < ApplicationRecord
  include NormalizesPhoneNumber

  # == Attributes ==

  sig { returns(T.nilable(Phonelib::Phone)) }
  def phone
    if (number = phone_number)
      Phonelib.parse(number)
    end
  end

  # == Normalizations ==

  normalizes_phone_number :phone_number

  # == Validations ==

  validates :lid, presence: true, uniqueness: true
  validates :phone_number,
            phone: { possible: true, types: :mobile, extensions: false },
            allow_nil: true

  # == Helpers ==

  sig { params(payload: T::Hash[String, T.untyped]).returns(WhatsappUser) }
  def self.find_or_create_from_webhook_payload!(payload)
    event = payload.fetch("event")
    case event
    when "messages.upsert"
      messages = payload.dig("data", "messages")
      key = messages.fetch("key")

      lid = if key.fetch("fromMe")
        application_jid
      else
        key.fetch("participantLid")
      end
      phone_number_jid = key["participantPn"]
      phone_number = key["cleanedParticipantPn"]
      display_name = messages["pushName"]

      user = WhatsappUser.find_or_initialize_by(lid:) do |user|
        user.phone_number = phone_number
        user.phone_number_jid = phone_number_jid
      end
      user.display_name = display_name
      user.save!
      user
    else
      raise "Unsupported event: #{event}"
    end
  end

  sig { params(jids: T::Array[String]).returns(WhatsappUser::PrivateRelation) }
  def self.from_mentioned_jids(jids)
    where(phone_number_jid: jids).or(where(lid: jids))
  end
end
