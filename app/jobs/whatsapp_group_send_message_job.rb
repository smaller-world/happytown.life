# typed: true
# frozen_string_literal: true

class WhatsappGroupSendMessageJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==
  sig { params(group: WhatsappGroup, text: String).void }
  def perform(group, text)
    group.send_message(text)
  end
end
