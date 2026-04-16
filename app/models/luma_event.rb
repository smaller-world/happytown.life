# typed: true
# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: luma_events
#
#  id             :uuid             not null, primary key
#  description    :text             not null
#  description_md :text             not null
#  duration       :tstzrange        not null
#  geo_address    :jsonb
#  geo_location   :geography        point, 4326
#  name           :string           not null
#  tag_ids        :string           default([]), not null, is an Array
#  time_zone_name :string           not null
#  url            :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  luma_id        :string           not null
#
# Indexes
#
#  index_luma_events_on_luma_id  (luma_id) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class LumaEvent < ApplicationRecord
  # == Configuration ==

  STALE_AFTER = T.let(1.day, ActiveSupport::Duration)

  # == Attributes ==

  sig { returns(RGeo::Geographic::Factory) }
  def self.geo_location_factory
    RGeo::Geographic.spherical_factory(srid: 4326)
  end
  delegate :geo_location_factory, to: :class, private: true

  sig { returns(ActiveSupport::TimeZone) }
  def time_zone
    ActiveSupport::TimeZone.new(time_zone_name)
  end

  sig { returns(T::Range[ActiveSupport::TimeWithZone]) }
  def duration
    start_at..end_at
  end

  sig { returns(ActiveSupport::TimeWithZone) }
  def start_at
    self[:duration].begin.in_time_zone(time_zone)
  end

  sig { returns(ActiveSupport::TimeWithZone) }
  def end_at
    self[:duration].end.in_time_zone(time_zone)
  end

  sig { returns(T::Boolean) }
  def stale?
    updated_at < STALE_AFTER.ago
  end

  # == Associations ==

  sig { returns(T::Array[LumaEventTag]) }
  def tags
    LumaEventTag.where(luma_id: tag_ids).to_a
  end

  # == Scopes ==

  scope :stale, -> { where(updated_at: ...STALE_AFTER.ago) }

  # == Importing ==

  sig { returns(T::Array[LumaEvent]) }
  def self.import_new
    cursor = T.let(nil, T.nilable(String))
    events = T.let([], T::Array[LumaEvent])
    latest_event_start_at = LumaEvent
      .order(duration: :desc)
      .pick(Arel.sql("UPPER(duration)"))

    loop do
      response = HappyTown.luma.list_events(
        sort_column: "start_at",
        sort_direction: "desc nulls last",
        pagination_cursor: cursor,
        after: latest_event_start_at,
      )
      response.events.each do |event|
        # Stop at undated or past events (sorted desc, so once we hit a past
        # event, all remaining are past too)
        break if event.start_at < Time.zone.now

        events << upsert_from_api!(event)
      end

      break unless response.has_more

      cursor = response.next_cursor
    end

    events
  end

  sig { void }
  def self.import
    new_events = import_new
    logger.info("Imported #{new_events.size} new Luma events")
    reimported_count = T.let(0, Integer)
    stale.find_each do |event|
      event.reimport_later
      reimported_count += 1
    end
    if reimported_count > 0
      logger.info(
        "Scheduled reimport for #{reimported_count} stale Luma events",
      )
    end
  end

  sig { void }
  def self.import_later
    ImportLumaEventsJob.perform_later
  end

  sig { void }
  def reimport
    response = HappyTown.luma.get_event(luma_id)
    update_from_api!(response.event)
  end

  sig { void }
  def reimport_later
    ReimportLumaEventJob.perform_later(self)
  end

  sig { params(api_event: Luma::Event).returns(LumaEvent) }
  def self.upsert_from_api!(api_event)
    find_or_initialize_by(luma_id: api_event.api_id).tap do |event|
      event.update_from_api!(api_event)
    end
  end

  sig { params(api_event: Luma::Event).void }
  def update_from_api!(api_event)
    geo_location = if (latitude = api_event.geo_latitude) &&
        (longitude = api_event.geo_longitude)
      geo_location_factory.point(longitude, latitude)
    end
    update!(
      name: api_event.name,
      description: api_event.description,
      description_md: api_event.description_md,
      duration: api_event.start_at..api_event.end_at,
      time_zone_name: api_event.timezone,
      geo_address: api_event.geo_address_json,
      geo_location:,
      url: api_event.url,
      tag_ids: api_event.tags.map(&:id),
    )
  end

  # == Methods ==

  sig do
    params(tag_id: String, only: T.nilable(T::Array[Symbol]))
      .returns(T.nilable(LumaEvent))
  end
  def self.next_event_for_tag_id(tag_id, only: nil)
    time_zone = time_zone_for_tag_id(tag_id) or return
    day_start = time_zone.now.beginning_of_day
    relation = where("? = ANY(tag_ids)", tag_id)
      .where("LOWER(duration) >= ?", day_start)
      .where("LOWER(duration) < ?", day_start + 1.week)
      .order(Arel.sql("LOWER(duration) ASC"))
    if only
      relation = T.cast(relation.select(*T.unsafe(only)), PrivateRelation)
    end
    relation.first
  end

  private

  sig { params(tag_id: String).returns(T.nilable(ActiveSupport::TimeZone)) }
  private_class_method def self.time_zone_for_tag_id(tag_id)
    name = where("LOWER(duration) >= NOW()")
      .where("? = ANY(tag_ids)", tag_id)
      .order(Arel.sql("LOWER(duration) ASC"))
      .pick(:time_zone_name) or return
    ActiveSupport::TimeZone.new(name)
  end
end
