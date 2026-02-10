# typed: true
# frozen_string_literal: true

class SendWhatsappGroupIntroJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { params(group: WhatsappGroup).void }
  def perform(group)
    group.send_intro
  end
end
