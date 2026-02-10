# typed: true
# frozen_string_literal: true

class SendWhatsappGroupMessageJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { params(group: WhatsappGroup, text: String, options: T.untyped).void }
  def perform(group, text, **options)
    group.send_message(text, **options)
  end
end
