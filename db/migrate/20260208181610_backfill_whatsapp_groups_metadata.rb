# frozen_string_literal: true

class BackfillWhatsappGroupsMetadata < ActiveRecord::Migration[8.1]
  def up
    groups = WhatsappGroup.where(metadata_imported_at: nil).to_a
    return if groups.empty?

    groups.first.import_metadata
    groups.drop(1).each(&:import_metadata_later)
  end
end
