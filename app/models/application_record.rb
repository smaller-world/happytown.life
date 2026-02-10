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

  # == Typechecking ==

  # Support runtime type-checking for Sorbet-generated types.
  PrivateRelation = ActiveRecord::Relation
  PrivateRelationWhereChain = ActiveRecord::Relation
  PrivateAssociationRelation = ActiveRecord::AssociationRelation
  PrivateAssociationRelationWhereChain = ActiveRecord::AssociationRelation
  PrivateCollectionProxy = ActiveRecord::Associations::CollectionProxy

  # == Helpers ==

  sig { returns(String) }
  def self.application_jid
    Rails.configuration.x.whatsapp_jid
  end

  delegate :application_jid, to: :class
end
