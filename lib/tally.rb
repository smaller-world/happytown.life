# typed: true
# frozen_string_literal: true

class Tally
  extend T::Sig

  # == Models ==

  class Question < T::Struct
    const :key, String
    const :label, String
    const :type, String
  end

  class Field < T::Struct
    const :key, String
    const :label, String
    const :type, String
    const :value, T.untyped # rubocop:disable Sorbet/ForbidUntypedStructProps
  end

  class Submission < T::Struct
    const :submission_id, String
    const :response_id, String
    const :respondent_id, String
    const :form_id, String
    const :created_at, ActiveSupport::TimeWithZone
    const :fields, T::Array[Field]
  end

  class ListSubmissionsResponse < T::Struct
    const :page, Integer
    const :limit, Integer
    const :has_more, T::Boolean
    const :questions, T::Array[Question]
    const :submissions, T::Array[Submission]
  end

  # == Exceptions ==

  class Error < StandardError; end

  class BadResponse < Error
    extend T::Sig

    sig { params(response: HTTP::Response).void }
    def initialize(response)
      @response = response
      super("Tally API error (status #{response.code}): #{response.parse}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response
  end

  class TooManyRequests < BadResponse; end

  # == Configuration ==

  sig { params(api_key: String).void }
  def initialize(api_key:)
    @session = T.let(
      HTTP
        .use(logging: { logger: Rails.logger.tagged(self.class.name) })
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
        key: q.fetch("key"),
        label: q.fetch("label"),
        type: q.fetch("type"),
      )
    end
    submissions = response.fetch("submissions").map do |s|
      fields = s.fetch("fields").map do |f|
        Field.new(
          key: f.fetch("key"),
          label: f.fetch("label"),
          type: f.fetch("type"),
          value: f.fetch("value"),
        )
      end
      Submission.new(
        submission_id: s.fetch("submissionId"),
        response_id: s.fetch("responseId"),
        respondent_id: s.fetch("respondentId"),
        form_id: s.fetch("formId"),
        created_at: Time.zone.parse(s.fetch("createdAt")),
        fields:,
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
