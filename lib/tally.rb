# typed: true
# frozen_string_literal: true

module Tally
  extend T::Sig
  include TaggedLogging

  # == Models ==

  class Question < T::Struct
    const :id, String
    const :title, T.nilable(String)
    const :type, String
  end

  class Response < T::Struct
    const :id, String
    const :question_id, String
    const :answer, T.untyped # rubocop:disable Sorbet/ForbidUntypedStructProps
  end

  class Submission < T::Struct
    const :id, String
    const :respondent_id, String
    const :form_id, String
    const :submitted_at, ActiveSupport::TimeWithZone
    const :responses, T::Array[Response]
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
      @error_type = T.let(nil, T.nilable(String))
      payload = response.parse
      @message = T.let(
        case payload
        when Hash
          @error_type = payload.fetch("errorType")
          payload.fetch("message")
        when String
          payload
        else
          raise "Unexpected error data: #{payload.inspect}"
        end,
        String,
      )
      descriptor = @error_type || "status #{response.code}"
      super("Tally API error (#{descriptor}): #{@message}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response

    sig { returns(T.nilable(String)) }
    attr_reader :error_type

    sig { returns(String) }
    attr_reader :message
  end

  class TooManyRequests < BadResponse; end
end
