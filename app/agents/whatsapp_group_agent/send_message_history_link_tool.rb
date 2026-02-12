# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent
  module SendMessageHistoryLinkTool
    extend T::Sig
    extend T::Helpers

    requires_ancestor { WhatsappGroupAgent }

    extend ActiveSupport::Concern

    # == Tool ==

    SEND_MESSAGE_HISTORY_LINK_TOOL = {
      name: "send_message_history_link",
      description:
        "send a message to containing the group's full message history URL.",
    }

    sig { returns(String) }
    def send_message_history_link
      group = group!
      jid = group.jid
      begin
        history_url = message_history_whatsapp_group_url(group)
        tag_logger do
          logger.info("Sending history link to group #{jid}: #{history_url}")
        end
        group!.send_message(text: "see older messages: #{history_url}")
        tag_logger do
          logger.info("Sending pin-message-instructions to group #{jid}")
        end
        text = <<~EOF.squish
          you can pin that message so new group members can see past messages.
          this video shows you how to do it.
        EOF
        group.send_video_message(
          video_url: video_url("pin_message_instructions.mp4", host: root_url),
          text:,
        )
        "OK"
      rescue => error
        tag_logger do
          logger.error(
            "Failed to send message history link to group #{jid}: #{error}",
          )
        end
        "ERROR: #{error}"
      end
    end
  end
end
