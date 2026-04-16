# typed: true
# frozen_string_literal: true

module Luma
  extend T::Sig

  # == Models ==

  class Tag < T::Struct
    const :id, String
    const :name, String
  end

  class Event < T::Struct
    const :api_id, String
    const :name, String
    const :description, String
    const :description_md, String
    const :start_at, ActiveSupport::TimeWithZone
    const :end_at, ActiveSupport::TimeWithZone
    const :timezone, String
    const :geo_address_json, T.nilable(T::Hash[String, T.untyped])
    const :geo_latitude, T.nilable(String)
    const :geo_longitude, T.nilable(String)
    const :url, String
    const :tags, T::Array[Tag]
  end

  class ListEventsResponse < T::Struct
    const :events, T::Array[Event]
    const :has_more, T::Boolean
    const :next_cursor, T.nilable(String)
  end

  class GetEventResponse < T::Struct
    const :event, Event
  end

  # == Exceptions ==

  class Error < StandardError; end

  class BadResponse < StandardError
    extend T::Sig

    sig { params(response: HTTP::Response).void }
    def initialize(response)
      @response = response
      super("Luma API error (status #{response.code}): #{response.parse}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response
  end

  class TooManyRequests < BadResponse; end
end
