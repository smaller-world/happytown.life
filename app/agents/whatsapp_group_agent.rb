# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent < ApplicationAgent
  # == Hooks ==

  before_action :set_instructions_context

  # == Tool Definitions ==

  UPDATE_SETTINGS_TOOL = {
    name: "update_settings",
    description: "update the group's settings. use when a group admin asks " \
      "to change a setting.",
    parameters: {
      type: "object",
      properties: {
        record_full_message_history: {
          type: "boolean",
          description: "record full message history for this group?",
        },
      },
      required: ["record_full_message_history"],
    },
  }

  SEND_MESSAGE_TOOL = {
    name: "send_message",
    description: "send a message to everyone in the group.",
    parameters: {
      type: "object",
      properties: {
        message: {
          type: "string",
        },
      },
      required: ["message"],
    },
  }

  SEND_REPLY_TOOL = {
    name: "send_reply",
    description: "send a reply to a specific message.",
    parameters: {
      type: "object",
      properties: {
        reply_to: {
          type: "string",
          description: "the message ID to reply to.",
        },
        message: {
          type: "string",
        },
      },
    },
  }

  # == Actions ==

  sig { void }
  def introduce_yourself
    prompt
  end

  sig { void }
  def reply
    @message = message!
    prompt(tools: [SEND_MESSAGE_TOOL, SEND_REPLY_TOOL])
  end

  # == Tools ==

  sig { params(record_full_message_history: T::Boolean).void }
  def update_settings(record_full_message_history:)
    group!.update!(
      record_full_message_history_since:
        record_full_message_history ? Time.current : nil,
    )
  end

  sig { params(message: String).void }
  def send_message(message:)
    group!.send_message(message)
  end

  sig { params(message: String, reply_to: String).void }
  def send_reply(message:, reply_to:)
    group!.send_message(message, reply_to:)
  end

  private

  # == Helpers ==

  sig { returns(WhatsappGroup) }
  def group!
    params.fetch(:group)
  end

  sig { returns(WhatsappMessage) }
  def message!
    params.fetch(:message)
  end

  sig { void }
  def set_instructions_context
    @group = group!
    @group_settings = {
      record_full_message_history:
        @group.record_full_message_history_since.present?,
    }
  end
end
