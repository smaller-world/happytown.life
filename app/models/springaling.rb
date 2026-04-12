# typed: true
# frozen_string_literal: true

module Springaling
  extend T::Sig

  sig { returns(String) }
  def self.tally_form_id = configuration.tally_form_id!

  sig { returns(String) }
  def self.notion_data_source_id = configuration.notion_data_source_id!

  sig { params(submission: Tally::Submission).returns(T::Hash[String, T.untyped]) }
  def self.notion_page_properties_from_tally_submission(submission)
    raise NotImplementedError,
          "Springaling.notion_page_properties_from_tally_submission is not yet " \
            "implemented. Define the mapping from Tally::Submission fields to " \
            "Notion page properties."
  end

  private

  sig { returns(T.untyped) }
  private_class_method def self.configuration
    Rails.configuration.x.springaling
  end
end
