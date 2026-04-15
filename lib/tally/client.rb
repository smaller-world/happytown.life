# typed: true
# frozen_string_literal: true

module Tally
  class Client
    extend T::Sig
    include TaggedLogging

    # == Configuration ==

    sig { params(api_key: String).void }
    def initialize(api_key:)
      @session = T.let(
        HTTP
          .use(logging: { logger: tagged_logger })
          .base_uri("https://api.tally.so")
          .auth("Bearer #{api_key}")
          .headers("tally-version" => "2025-02-01"),
        HTTP::Session,
      )
    end

    # == Methods ==

    sig do
      params(
        form_id: String,
        after_id: T.nilable(String),
        page: T.nilable(Integer),
        limit: T.nilable(Integer),
      ).returns(ListSubmissionsResponse)
    end
    def list_form_submissions(form_id:, after_id: nil, page: nil, limit: nil)
      params = {
        afterId: after_id,
        page:,
        limit:,
      }.compact
      response = get!("/forms/#{form_id}/submissions", params:)
      questions = response.fetch("questions").map do |q|
        Question.new(
          id: q.fetch("id"),
          title: q.fetch("title"),
          type: q.fetch("type"),
        )
      end
      submissions = response.fetch("submissions").map do |s|
        responses = s.fetch("responses").map do |r|
          Response.new(
            id: r.fetch("id"),
            question_id: r.fetch("questionId"),
            answer: r.fetch("answer"),
          )
        end
        Submission.new(
          id: s.fetch("id"),
          respondent_id: s.fetch("respondentId"),
          form_id: s.fetch("formId"),
          submitted_at: Time.zone.parse(s.fetch("submittedAt")),
          responses:,
        )
      end
      ListSubmissionsResponse.new(
        page: response.fetch("page"),
        limit: response.fetch("limit"),
        has_more: response.fetch("hasMore"),
        questions:,
        submissions:,
      )
    end

    private

    # == Helpers ==

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
