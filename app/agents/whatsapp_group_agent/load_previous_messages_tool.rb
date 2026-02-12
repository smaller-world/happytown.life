# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent
  module LoadPreviousMessagesTool
    extend T::Sig
    extend T::Helpers

    requires_ancestor { WhatsappGroupAgent }

    extend ActiveSupport::Concern

    # == Tool ==

    LOAD_PREVIOUS_MESSAGES_TOOL = {
      name: "load_previous_messages",
      description:
        "load a bounded window of previous messages from the group's message " \
        "history.",
      parameters: {
        type: "object",
        properties: {
          before_message_id: {
            type: "string",
            description: "messages before this message ID will be loaded",
          },
          limit: {
            type: "integer",
            description: "maximum number of messages to load",
            minimum: 1,
            maximum: 50,
            default: 20,
          },
        },
        required: ["before_message_id", "limit"],
      },
    }

    sig { params(before_message_id: String, limit: Integer).returns(String) }
    def load_previous_messages(before_message_id:, limit:)
      group = group!
      jid = group.jid
      tag_logger do
        logger.info(
          "Loading previous messages from group #{jid} " \
            "(before #{before_message_id})",
        )
      end
      before_message = group.messages.find_by!(whatsapp_id: before_message_id)
      previous_messages = before_message.previous_messages(limit:)
      formatted_messages = T.let([], T::Array[String])
      previous_messages.reverse_each.with_index do |message, index|
        heading = "## MESSAGE #{index + 1}:"
        content = render_to_string(
          partial: "agents/whatsapp_group/message",
          locals: {
            message:,
          },
        )
        formatted_messages << [heading, content].join("\n")
      end
      formatted_messages.join("\n\n")
    rescue => error
      tag_logger do
        logger.error("Failed to load previous messages from group #{jid}: #{error}")
      end
      "ERROR: #{error}"
    end

    private

    # == Helpers ==

    sig { params(text: String).returns(T::Array[String]) }
    def mentioned_jids_in(text)
      mentions = text.scan(/@(\d+)/).flatten
      mentioned_numbers = mentions.map do |mention|
        phone = Phonelib.parse(mention.delete_prefix("@"))
        phone.to_s
      end
      WhatsappUser.where(phone_number: mentioned_numbers).distinct.pluck(:lid)
    end
  end
end
