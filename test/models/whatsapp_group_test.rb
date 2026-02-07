# typed: false
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
require "test_helper"

class WhatsappGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
