# typed: true
# frozen_string_literal: true

module Springaling
  extend T::Sig

  # == Tally Form Question IDs ==

  QUESTION_NAME = "Woz25a"
  QUESTION_CONTACT = "axd9Yq"
  QUESTION_EVENT_IDEA = "6kNL2B"
  QUESTION_NEEDS_SUPPORT = "7Dxq2A"
  QUESTION_SUGGESTED_DATE = "yyYMkx"
  QUESTION_ALT_DATE = "XG0LyY"
  QUESTION_TIME = "0MOd5j"

  # == Tally Submission Timezone ==

  TIMEZONE_NAME = "America/Toronto"
  TIMEZONE = ActiveSupport::TimeZone.new(TIMEZONE_NAME)

  # == Configuration ==

  sig { returns(String) }
  def self.tally_form_id = configuration.tally_form_id!

  sig { returns(String) }
  def self.notion_data_source_id = configuration.notion_data_source_id!

  # == Methods ==

  sig { params(submission: Tally::Submission).returns(T::Hash[String, T.untyped]) }
  def self.notion_page_properties_from_tally_submission(submission)
    fields = submission.responses.to_h { |r| [ r.question_id, r.answer ] }

    suggested_date = fields[QUESTION_SUGGESTED_DATE]
    alt_date = fields[QUESTION_ALT_DATE]
    time = fields[QUESTION_TIME]

    {
      "name" => {
        "title" => [ {
          "text" => { "content" => fields[QUESTION_NAME].strip },
        } ],
      },
      "contact" => {
        "rich_text" => [ {
          "type" => "text",
          "text" => { "content" => fields[QUESTION_CONTACT] },
        } ],
      },
      "event idea" => {
        "rich_text" => [ {
          "type" => "text",
          "text" => { "content" => fields[QUESTION_EVENT_IDEA] },
        } ],
      },
      "needs support with" => {
        "multi_select" => Array(fields[QUESTION_NEEDS_SUPPORT])
          .map { |v| { "name" => v } },
      },
      "suggested date" => notion_date_value(suggested_date, time),
      "tally submission ID" => {
        "rich_text" => [ {
          "type" => "text",
          "text" => { "content" => submission.id },
        } ],
      },
      "submitted at" => {
        "date" => {
          "start" => submission.submitted_at.in_time_zone(TIMEZONE).iso8601,
          "end" => nil,
        },
      },
    }.tap do |properties|
      # Only include alt date if it differs from the suggested date
      if alt_date.present? && alt_date != suggested_date
        properties["alt date"] = notion_date_value(alt_date, time)
      end
    end
  end

  private

  # == Helpers ==

  sig do
    params(date_string: T.nilable(String), time_string: T.nilable(String))
      .returns(T.nilable(T::Hash[String, T.untyped]))
  end
  private_class_method def self.notion_date_value(date_string, time_string)
    if date_string.present?
      date = Date.parse(date_string)
      start = if time_string.present?
        TIMEZONE.parse(time_string, date).iso8601
      else
        date.iso8601
      end
      { "date" => { "start" => start, "end" => nil } }
    end
  end

  sig { returns(T.untyped) }
  private_class_method def self.configuration
    Rails.configuration.x.springaling
  end
end
