# typed: true
# frozen_string_literal: true

require "test_helper"

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: whatsapp_groups
#
#  id                      :uuid             not null, primary key
#  description             :text
#  intro_sent_at           :timestamptz
#  jid                     :string           not null
#  memberships_imported_at :timestamptz
#  metadata_imported_at    :timestamptz
#  profile_picture_url     :string
#  subject                 :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_whatsapp_groups_on_intro_sent_at            (intro_sent_at)
#  index_whatsapp_groups_on_jid                      (jid) UNIQUE
#  index_whatsapp_groups_on_memberships_imported_at  (memberships_imported_at)
#  index_whatsapp_groups_on_metadata_imported_at     (metadata_imported_at)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class WhatsappGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
