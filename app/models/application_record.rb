# typed: true
# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  extend T::Sig
  extend T::Helpers

  abstract!

  # == Configuration ==

  primary_abstract_class
end
