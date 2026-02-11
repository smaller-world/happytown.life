# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent < ApplicationAgent
  # == Hooks ==

  before_action :set_instructions_context
  around_generation :send_typing_indicator_while

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

  SEND_MESSAGE_HISTORY_LINK_TOOL = {
    name: "send_message_history_link",
    description: "send a message to the group containing the group's full " \
      "message history URL.",
  }

  # == Actions ==

  sig { void }
  def introduce_yourself
    prompt(tools: [SEND_MESSAGE_TOOL], tool_choice: "required")
  end

  sig { void }
  def reply
    @message = message!
    prompt(
      tools: [SEND_REPLY_TOOL, SEND_MESSAGE_HISTORY_LINK_TOOL],
      tool_choice: "required",
    )
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
    jid = group!.jid
    tag_logger do
      Rails.logger.info("Sending message to group (#{jid}): #{message}")
    end
    mentioned_jids = mentioned_jids_in(message)
    group!.send_message(message, mentioned_jids:)
    reply_with("Message sent successfully.")
  rescue => error
    tag_logger do
      Rails.logger.error(
        "Failed to send message to group (#{jid}): #{error.message}",
      )
    end
    reply_with("Failed to send message: #{error.message}")
  end

  sig { params(message: String).void }
  def send_reply(message:)
    sender = message!.sender!
    if mentioned_jids_in(message).exclude?(sender.lid)
      tag_logger do
        Rails.logger.info(
          "Adding sender mention (#{sender.embedded_mention}) to reply " \
            "message: #{message}",
        )
      end
      message = "#{sender.embedded_mention} #{message}"
    end
    send_message(message:)
  end

  sig { void }
  def send_message_history_link
    history_url = message_history_whatsapp_group_url(group!)
    send_message(message: "see older messages: #{history_url}")
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
  def send_typing_indicator_while(&block)
    indicator_thread = Thread.new do
      group!.send_typing_indicator
      sleep(rand(1.2..2.5))
      loop do
        group!.send_typing_indicator
        sleep(rand(0.8..2.0))
      end
    end
    yield
  ensure
    indicator_thread&.kill
  end

  sig { params(message: String).returns(T::Array[String]) }
  def mentioned_jids_in(message)
    mentioned_jids = message.scan(/@(\d+)/).flatten
    WhatsappUser.where(phone_number_jid: mentioned_jids).distinct.pluck(:lid)
  end

  sig { params(text: String).void }
  def reply_with(text)
    prompt(content_type: "text/plain") do |format|
      format.text { render plain: text }
    end
  end
end
