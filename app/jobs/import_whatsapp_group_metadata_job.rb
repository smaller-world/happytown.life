# typed: true
# frozen_string_literal: true

class ImportWhatsappGroupMetadataJob < ApplicationJob
  # == Configuration ==
  queue_as :default

  # == Job ==
  sig { params(group: WhatsappGroup).void }
  def perform(group)
    group.import_metadata
  end
end
