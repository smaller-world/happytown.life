# typed: true
# frozen_string_literal: true

require "rails"
require "http"

class Notion
  extend T::Sig

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

  # == Configuration ==

  sig { params(integration_secret: String).void }
  def initialize(integration_secret:)
    @session = T.let(
      HTTP
        .use(logging: { logger: Rails.logger.tagged(self.class.name) })
        .base_uri("https://api.notion.com")
        .auth("Bearer #{integration_secret}")
        .headers("Notion-Version" => "2026-03-11"),
      HTTP::Session,
    )
  end

  # == Methods ==

  sig do
    params(
      data_source_id: String,
      filter: T.nilable(T::Hash[String, T.untyped]),
      sorts: T.nilable(T::Array[T::Hash[String, T.untyped]]),
      start_cursor: T.nilable(String),
      page_size: T.nilable(Integer),
    ).returns(QueryDataSourceResponse)
  end
  def query_data_source(data_source_id:, filter: nil, sorts: nil, start_cursor: nil, page_size: nil)
    body = {
      filter:,
      sorts:,
      start_cursor:,
      page_size:,
    }.compact
    response = post!("/v1/data_sources/#{data_source_id}/query", json: body)
    results = response.fetch("results").map do |page|
      Page.new(
        id: page.fetch("id"),
        url: page.fetch("url"),
        created_time: Time.zone.parse(page.fetch("created_time")),
        properties: page.fetch("properties"),
      )
    end
    QueryDataSourceResponse.new(
      results:,
      has_more: response.fetch("has_more"),
      next_cursor: response["next_cursor"],
    )
  end

  sig do
    params(
      parent: T::Hash[String, T.untyped],
      properties: T::Hash[String, T.untyped],
    ).returns(Page)
  end
  def create_page(parent:, properties:)
    response = post!("/v1/pages", json: { parent:, properties: })
    Page.new(
      id: response.fetch("id"),
      url: response.fetch("url"),
      created_time: Time.zone.parse(response.fetch("created_time")),
      properties: response.fetch("properties"),
    )
  end

  private

  # == Helpers ==

  sig { params(path: String, options: T.untyped).returns(T.untyped) }
  def post!(path, **options)
    response = @session.post(path, **options)
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
