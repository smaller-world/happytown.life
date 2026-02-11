# typed: true
# frozen_string_literal: true

module AgentHelper
  extend T::Sig
  extend T::Helpers

  requires_ancestor { Kernel }

  sig { returns(String) }
  def application_user_jid
    Rails.configuration.x.whatsapp_jid
  end

  sig { params(user: WhatsappUser).returns(String) }
  def whatsapp_user_identity(user)
    if user.lid == application_user_jid
      "(YOURSELF)"
    else
      display_text = user.display_name || "(UNKNOWN USER)"
      if (number = user.phone&.sanitized)
        display_text += " <#{number}>"
      end
      display_text
    end
  end

  sig { params(message: WhatsappMessage).returns(String) }
  def quoted_participant_identity(message)
    if (sender = message.quoted_message&.sender)
      whatsapp_user_identity(sender)
    elsif (jid = message.quoted_participant_jid)
      if jid == application_user_jid
        "(YOURSELF)"
      else
        "(UNKNOWN USER)"
      end
    else
      "(UNKNOWN USER)"
    end
  end

  sig { params(message: WhatsappMessage).returns(String) }
  def message_body_with_inlined_mentions(message)
    body = message.body
    message.mentioned_users.each do |user|
      lid = user.lid.delete_suffix("@lid")
      body.gsub!("@#{lid}", "@#{whatsapp_user_identity(user)}")
    end
    body
  end

  sig { params(message: WhatsappMessage).returns(T.nilable(String)) }
  def quoted_message_body_with_inlined_mentions(message)
    if (quoted_message = message.quoted_message)
      message_body_with_inlined_mentions(quoted_message)
    else
      message.quoted_message_body
    end
  end
end
