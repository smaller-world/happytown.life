# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_users
#
#  id                   :uuid             not null, primary key
#  display_name         :string
#  lid                  :string           not null
#  metadata_imported_at :timestamptz
#  phone_number         :string
#  phone_number_jid     :string
#  profile_picture_url  :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_whatsapp_users_on_lid                   (lid) UNIQUE
#  index_whatsapp_users_on_metadata_imported_at  (metadata_imported_at)
#  index_whatsapp_users_on_phone_number          (phone_number) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
require "test_helper"

class WhatsappUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
