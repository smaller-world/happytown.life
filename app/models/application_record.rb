# typed: true
# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  extend T::Sig
  extend T::Helpers

  abstract!

  # == Configuration ==

  primary_abstract_class

  # == Scopes ==

  scope :chronological, -> { order(:created_at) }
  scope :reverse_chronological, -> { order(created_at: :desc) }
end
