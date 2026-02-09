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
require "test_helper"

class WhatsappMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
