# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent
  module SendReplyTool
    extend T::Sig
    extend T::Helpers

    requires_ancestor { WhatsappGroupAgent }

    extend ActiveSupport::Concern

    include SendMessageTool

    # == Tool ==

    SEND_REPLY_TOOL = {
      name: "send_reply",
      description: "send a reply to the received message.",
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
    def send_reply(text:)
      sender = message!.sender!
      if mentioned_jids_in(text).exclude?(sender.lid)
        tag_logger do
          Rails.logger.info(
            "Adding sender mention (#{sender.embedded_mention}) to reply " \
              "message: #{text}",
          )
        end
        text = "#{sender.embedded_mention} #{text}"
      end
      send_message(text:)
    end
  end
end
