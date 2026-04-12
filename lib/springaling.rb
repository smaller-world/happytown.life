# typed: true
# frozen_string_literal: true

require "rails"

module Springaling
  extend T::Sig

  # == Configuration ==

  sig { returns(String) }
  def self.tally_form_id = configuration.tally_form_id!

  sig { returns(String) }
  def self.notion_data_source_id = configuration.notion_data_source_id!

  private

  # == Helpers ==

  sig { returns(T.untyped) }
  private_class_method def self.configuration
    Rails.configuration.x.springaling
  end
end
