# typed: true
# frozen_string_literal: true

class WsapiMessageSender
  extend T::Sig

  include SmartProperties
  include ActiveModel::Serialization

  # == Attributes

  property! :id, accepts: String
  property! :lid, accepts: String
  property! :phone, accepts: String
  property! :is_me, accepts: [ true, false ]

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def attributes
    { id:, lid:, phone: }
  end
end
