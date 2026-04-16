# typed: true
# frozen_string_literal: true

module Luma
  class Client
    extend T::Sig
    include TaggedLogging

    # == Configuration ==

    sig { params(api_key: String).void }
    def initialize(api_key:)
      @session = T.let(
        HTTP
        .use(logging: { logger: tagged_logger })
        .base_uri("https://public-api.luma.com")
        .headers("x-luma-api-key" => api_key),
        HTTP::Session,
      )
    end

    # == Methods ==

    sig do
      params(
        after: T.nilable(ActiveSupport::TimeWithZone),
        before: T.nilable(ActiveSupport::TimeWithZone),
        pagination_cursor: T.nilable(String),
        pagination_limit: T.nilable(Integer),
        sort_column: T.nilable(String),
        sort_direction: T.nilable(String),
      ).returns(ListEventsResponse)
    end
    def list_events(
      after: nil,
      before: nil,
      pagination_cursor: nil,
      pagination_limit: nil,
      sort_column: nil,
      sort_direction: nil
    )
      params = {
        after: after&.iso8601,
        before: before&.iso8601,
        pagination_cursor:,
        pagination_limit:,
        sort_column:,
        sort_direction:,
      }.compact
      response = get!("/v1/calendar/list-events", params:)
      events = response.fetch("entries").map do |entry|
        event_data = entry.fetch("event")
        tags_data = entry.fetch("tags")
        parse_event(event_data, tags_data:)
      end
      ListEventsResponse.new(
        events:,
        has_more: response.fetch("has_more"),
        next_cursor: response["next_cursor"],
      )
    end

    sig { params(id: String).returns(GetEventResponse) }
    def get_event(id)
      response = get!("/v1/event/get", params: { id: })
      event_data = response.fetch("event")
      tags_data = event_data.fetch("tags")
      GetEventResponse.new(event: parse_event(event_data, tags_data:))
    end

    private

    # == Helpers ==

    sig do
      params(
        event_data: T::Hash[String, T.untyped],
        tags_data: T::Array[T::Hash[String, T.untyped]],
      ).returns(Event)
    end
    def parse_event(event_data, tags_data:)
      Event.new(
        api_id: event_data.fetch("api_id"),
        name: event_data.fetch("name"),
        description: event_data.fetch("description"),
        description_md: event_data.fetch("description_md"),
        start_at: Time.zone.parse(event_data.fetch("start_at")),
        end_at: Time.zone.parse(event_data.fetch("end_at")),
        timezone: event_data.fetch("timezone"),
        geo_address_json: event_data.fetch("geo_address_json"),
        geo_latitude: event_data.fetch("geo_latitude"),
        geo_longitude: event_data.fetch("geo_longitude"),
        url: event_data.fetch("url"),
        tags: tags_data.map do |tag|
          Tag.new(
            id: tag.fetch("id"),
            name: tag.fetch("name"),
          )
        end,
      )
    end

    sig { params(path: String, options: T.untyped).returns(T.untyped) }
    def get!(path, **options)
      response = @session.get(path, **options)
      check_response!(response)
      response.parse
    end

    sig { params(response: HTTP::Response).void }
    def check_response!(response)
      unless response.status.success?
        case response.code
        when 429
          raise TooManyRequests, response
        else
          raise BadResponse, response
        end
      end
    end
  end
end
