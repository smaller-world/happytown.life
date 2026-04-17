# typed: true
# frozen_string_literal: true

class SyncLumaEventToNotionJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: ->(event) { event }, on_conflict: :discard

  # == Job ==

  sig { params(event: LumaEvent).void }
  def perform(event)
    tag_logger do
      logger.info("Syncing Luma event to Notion: #{event.luma_id}")
    end
    event.sync_to_notion
  end
end
