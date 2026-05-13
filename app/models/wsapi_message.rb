# typed: true
# frozen_string_literal: true

class WsapiMessage
  extend T::Sig

  include SmartProperties
  include ActiveModel::Serialization

  # == Attributes

  property! :type, accepts:
             [
               "text",
               "media",
               "reaction",
               "contact",
               "contact_array",
               "pin_in_chat",
             ]
  property! :id, accepts: String
  property! :chat_id, accepts: String
  property! :time, accepts: Time
  property! :text, accepts: String
  property! :sender, accepts: WsapiMessageSender
  property! :is_group, accepts: [ true, false ]
  property :is_status, accepts: [ true, false ]

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def attributes
    { type:, id:, chat_id:, time:, text: }
  end

  sig { params(data: T::Hash[String, T.untyped]).returns(T.attached_class) }
  def self.from_event_data(data)
    attributes = data.transform_keys(&:underscore)
    if (type = attributes["type"])
      attributes["type"] = type.underscore
    end
    if (time = attributes["time"])
      attributes["time"] = Time.zone.parse(time)
    end
    if (sender = attributes["sender"]) && sender.is_a?(Hash)
      sender_attributes = sender.transform_keys(&:underscore)
      attributes["sender"] = WsapiMessageSender.new(**sender_attributes)
    end
    new(**attributes.symbolize_keys.slice(*properties.keys))
  end
end
