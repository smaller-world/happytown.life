# typed: true
# frozen_string_literal: true

module Notion
  extend T::Sig
  include TaggedLogging

  # == Models ==

  class Page < T::Struct
    const :id, String
    const :url, String
    const :created_time, ActiveSupport::TimeWithZone
    const :properties, T::Hash[String, T.untyped]
  end

  class QueryDataSourceResponse < T::Struct
    const :results, T::Array[Page]
    const :has_more, T::Boolean
    const :next_cursor, T.nilable(String)
  end

  # == Exceptions ==

  class Error < StandardError; end

  class BadResponse < StandardError
    extend T::Sig

    sig { params(response: HTTP::Response).void }
    def initialize(response)
      @response = response
      payload = response.parse
      @code = T.let(payload.fetch("code"), String)
      @message = T.let(payload.fetch("message"), String)
      @request_id = T.let(payload.fetch("request_id"), String)
      @additional_data = T.let(
        payload["additional_data"],
        T.nilable(T::Hash[String, T.untyped]),
      )
      super("Notion API error [#{@code}]: #{@message}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response

    sig { returns(String) }
    attr_reader :code

    sig { returns(String) }
    attr_reader :message

    sig { returns(String) }
    attr_reader :request_id

    sig { returns(T.nilable(T::Hash[String, T.untyped])) }
    attr_reader :additional_data
  end

  class TooManyRequests < BadResponse; end
end
