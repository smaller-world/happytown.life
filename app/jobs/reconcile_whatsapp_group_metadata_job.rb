# typed: true
# frozen_string_literal: true

class ReconcileWhatsappGroupMetadataJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { void }
  def perform
    WhatsappGroup
      .where(metadata_imported_at: nil)
      .or(WhatsappGroup.where(metadata_imported_at: ...1.day.ago))
      .find_each(&:import_metadata_later)
  end
end
