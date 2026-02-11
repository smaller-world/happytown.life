# typed: true
# frozen_string_literal: true

class ImportWhatsappGroupMetadataJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: ->(group) { group }, on_conflict: :discard
  retry_on WaSenderApi::TooManyRequests, wait: :polynomially_longer

  # == Job ==

  sig { params(group: WhatsappGroup).void }
  def perform(group)
    tag_logger do
      Rails.logger.info("Importing metadata for group: #{group.jid}")
    end
    group.import_metadata
  end
end
