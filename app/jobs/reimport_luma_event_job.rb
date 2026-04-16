# typed: true
# frozen_string_literal: true

class ReimportLumaEventJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: ->(event) { event }, on_conflict: :discard

  # == Job ==

  sig { params(event: LumaEvent).void }
  def perform(event)
    tag_logger do
      logger.info("Importing Luma event: #{event.luma_id}")
    end
    event.reimport
  end
end
