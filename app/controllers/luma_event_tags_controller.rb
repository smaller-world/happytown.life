# typed: true
# frozen_string_literal: true

class LumaEventTagsController < ApplicationController
  # == Filters ==

  allow_unauthenticated_access

  # == Actions ==

  # GET /luma_events_tags/:id/next_event
  def next_event
    tag = find_tag
    url = if (event = tag.next_event)
      event.url
    else
      Rails.configuration.x.luma_url
    end
    tracked_url = with_utm_source(url)
    redirect_to(tracked_url, status: :found, allow_other_host: true)
  end

  private

  # == Helpers ==

  sig { returns(LumaEventTag) }
  def find_tag
    LumaEventTag.find(params.fetch(:id))
  end

  sig { params(url: String).returns(String) }
  def with_utm_source(url)
    url = Addressable::URI.parse(url)
    query_values = url.query_values || {}
    query_values["utm_source"] = "happytown.life"
    url.query_values = query_values
    url.to_s
  end
end
