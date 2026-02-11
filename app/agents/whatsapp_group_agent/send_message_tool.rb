# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent
  module SendMessageTool
    extend T::Sig
    extend T::Helpers

    requires_ancestor { WhatsappGroupAgent }

    extend ActiveSupport::Concern

    # == Tool ==

    SEND_MESSAGE_TOOL = {
      name: "send_message",
      description: "send a message to everyone in the group.",
      parameters: {
        type: "object",
        properties: {
          text: {
            type: "string",
          },
        },
        required: ["text"],
      },
    }

    sig { params(text: String).void }
    def send_message(text:)
      jid = group!.jid
      tag_logger do
        Rails.logger.info("Sending message to group (#{jid}): #{text}")
      end
      mentioned_jids = mentioned_jids_in(text)
      group!.send_message(text:, mentioned_jids:)
      reply_with("Message sent successfully.")
    rescue => error
      tag_logger do
        Rails.logger.error(
          "Failed to send message to group (#{jid}): #{error.message}",
        )
      end
      reply_with("Failed to send message: #{error.message}")
    end

    private

    # == Helpers ==

    sig { params(message: String).returns(T::Array[String]) }
    def mentioned_jids_in(message)
      mentions = message.scan(/@(\d+)/).flatten
      mentioned_numbers = mentions.map do |mention|
        phone = Phonelib.parse(mention.delete_prefix("@"))
        phone.to_s
      end
      WhatsappUser.where(phone_number: mentioned_numbers).distinct.pluck(:lid)
    end
  end
end
