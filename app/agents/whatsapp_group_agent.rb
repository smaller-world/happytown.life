# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent < ApplicationAgent
  # == Hooks ==

  before_action :set_instructions_context
  around_action :indicate_typing_while

  # == Tool Definitions ==

  # UPDATE_SETTINGS_TOOL = {
  #   name: "update_settings",
  #   description: "update the group's settings. use when a group admin asks " \
  #     "to change a setting.",
  #   parameters: {
  #     type: "object",
  #     properties: {
  #       record_full_message_history: {
  #         type: "boolean",
  #         description: "record full message history for this group?",
  #       },
  #     },
  #     required: ["record_full_message_history"],
  #   },
  # }

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
    description: "send a reply to the received message.",
    parameters: {
      type: "object",
      properties: {
        message: {
          type: "string",
        },
      },
    },
  }

  # == Actions ==

  sig { void }
  def introduce_yourself
    prompt(tools: [SEND_MESSAGE_TOOL])
  end

  sig { void }
  def reply
    @message = message!
    prompt(tools: [SEND_REPLY_TOOL])
  end

  # == Tools ==

  # sig { params(record_full_message_history: T::Boolean).void }
  # def update_settings(record_full_message_history:)
  #   group!.update!(
  #     record_full_message_history_since:
  #       record_full_message_history ? Time.current : nil,
  #   )
  #   render_text("Settings updated successfully.")
  # rescue => error
  #   render_text("Failed to update settings: #{error.message}")
  # end

  sig { params(message: String).void }
  def send_message(message:)
    group!.send_message_later(message)
    render_text("Message sent successfully.")
  rescue => error
    render_text("Failed to send message: #{error.message}")
  end

  sig { params(message: String).void }
  def send_reply(message:)
    group!.send_message_later(message, reply_to: message!.message_id)
    render_text("Reply sent successfully.")
  rescue => error
    render_text("Failed to send reply: #{error.message}")
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
  end

  sig { params(block: T.proc.void).void }
  def indicate_typing_while(&block)
    group!.indicate_typing_while(&block)
  end

  sig { params(text: String).void }
  def render_text(text)
    prompt(content_type: "text/plain") do |format|
      format.text { render plain: text }
    end
  end
end
