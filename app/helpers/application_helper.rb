# typed: true
# frozen_string_literal: true

module ApplicationHelper
  extend T::Sig
  extend T::Helpers

  requires_ancestor { ActionView::Base }

  # == Methods ==
  sig do
    params(hash: T::Hash[Symbol, T.untyped], keys: Symbol)
      .returns(T::Hash[Symbol, T.untyped])
  end
  def delete_from(hash, *keys)
    removed_values = {}
    keys.each do |key|
      removed_values[key] = hash.delete(key) if hash.key?(key)
    end
    removed_values
  end
end
