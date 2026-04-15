# typed: true
# frozen_string_literal: true

module Notion
  class Client
    extend T::Sig
    include TaggedLogging

    # == Configuration ==

    sig { params(integration_secret: String).void }
    def initialize(integration_secret:)
      @session = T.let(
        HTTP
          .use(logging: { logger: tagged_logger })
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
end
