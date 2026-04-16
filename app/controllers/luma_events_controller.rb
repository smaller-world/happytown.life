# typed: true
# frozen_string_literal: true

class LumaEventsController < ApplicationController
  # == Filters ==

  allow_unauthenticated_access

  # == Actions ==

  # GET /luma_events/open=...
  def open
    tag_id = params.expect(:tag_id)
    url = if (event = LumaEvent.next_event_for_tag_id(tag_id, only: [ :url ]))
      event.url
    else
      Rails.configuration.x.luma_url
    end
    tracked_url = with_utm_source(url)
    redirect_to(tracked_url, status: :found, allow_other_host: true)
  end

  private

  # == Helpers ==

  sig { params(url: String).returns(String) }
  def with_utm_source(url)
    url = Addressable::URI.parse(url)
    query_values = url.query_values || {}
    query_values["utm_source"] = "happytown.life"
    url.query_values = query_values
    url.to_s
  end
end
