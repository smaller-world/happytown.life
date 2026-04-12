# typed: true
# frozen_string_literal: true

class Springaling::ImportTallySubmissionsJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: :global, on_conflict: :discard

  # == Job ==

  sig { void }
  def perform
    after_id = last_imported_submission_id
    submissions = fetch_new_tally_submissions(after_id:)
    submissions.each do |submission|
      HappyTown.notion.create_page(
        parent: {
          type: "data_source_id",
          data_source_id: Springaling.notion_data_source_id,
        },
        properties: Springaling.notion_page_properties_from_tally_submission(submission),
      )
    end
    logger.info("Imported #{submissions.size} Tally submissions")
  end

  private

  # == Helpers ==

  sig { returns(T.nilable(String)) }
  def last_imported_submission_id
    response = HappyTown.notion.query_data_source(
      data_source_id: Springaling.notion_data_source_id,
      filter: {
        property: "tally submission ID",
        rich_text: { is_not_empty: true },
      },
      sorts: [ { property: "submitted at", direction: "descending" } ],
      page_size: 1,
    )
    page = response.results.first or return
    rich_text = page.properties.dig("tally submission ID", "rich_text") || []
    rich_text.map { |t| t.fetch("plain_text") }.join.presence
  end

  sig { params(after_id: T.nilable(String)).returns(T::Array[Tally::Submission]) }
  def fetch_new_tally_submissions(after_id:)
    all = T.let([], T::Array[Tally::Submission])
    page_num = 1
    loop do
      response = HappyTown.tally.list_form_submissions(
        form_id: Springaling.tally_form_id,
        after_id:,
        page: page_num,
      )
      all.concat(response.submissions)
      break unless response.has_more

      page_num += 1
    end
    all.reverse
  end
end
