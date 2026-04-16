# typed: true
# frozen_string_literal: true

class LumaEventTag < ApplicationFrozenRecord
  # == Methods ==

  sig { returns(T.nilable(LumaEvent)) }
  def next_event
    LumaEvent.next_event_for_tag_id(luma_id)
  end
end
