# typed: true
# frozen_string_literal: true

class ImportLumaEventsJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: :global, on_conflict: :discard

  # == Job ==

  sig { void }
  def perform
    LumaEvent.import
  end
end
