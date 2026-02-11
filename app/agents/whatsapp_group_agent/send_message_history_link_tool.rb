# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent
  module SendMessageHistoryLinkTool
    extend T::Sig
    extend T::Helpers

    requires_ancestor { WhatsappGroupAgent }

    extend ActiveSupport::Concern
    include WhatsappMessaging
    include SendMessageTool

    # == Tool ==

    SEND_MESSAGE_HISTORY_LINK_TOOL = {
      name: "send_message_history_link",
      description: "send a message to the group containing the group's full " \
        "message history URL.",
    }

    sig { void }
    def send_message_history_link
      history_url = message_history_whatsapp_group_url(group!)
      send_message(text: "see older messages: #{history_url}")
    end
  end
end
