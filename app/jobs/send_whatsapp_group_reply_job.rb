# typed: true
# frozen_string_literal: true

class SendWhatsappGroupReplyJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { params(message: WhatsappMessage).void }
  def perform(message)
    message.send_reply unless message.reply_sent?
  end
end
