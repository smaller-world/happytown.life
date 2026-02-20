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
        "Send a message to containing the group's full message history URL.",
    }

    # == Execution ==

    sig { returns(String) }
    def send_message_history_link
      group = group!
      jid = group.jid
      begin
        history_url = message_history_whatsapp_group_url(group)
        instructions_video_url = view_context.video_url(
          "pin_message_instructions.mp4",
          host: root_url,
        )
        tag_logger do
          logger.info(
            "Sending message history link to group #{jid}: #{history_url}",
          )
        end
        group.send_message_history_link(history_url:, instructions_video_url:)
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
