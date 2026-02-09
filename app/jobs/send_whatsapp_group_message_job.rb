# typed: true
# frozen_string_literal: true

class SendWhatsappGroupMessageJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { params(group: WhatsappGroup, text: String).void }
  def perform(group, text)
    group.send_message(text)
  end
end
