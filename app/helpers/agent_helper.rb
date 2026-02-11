# typed: true
# frozen_string_literal: true

module AgentHelper
  extend T::Sig

  sig { returns(String) }
  def application_jid
    Rails.configuration.x.whatsapp_jid
  end

  sig { params(user: WhatsappUser).returns(String) }
  def whatsapp_user_identity(user)
    if user.lid == application_jid
      "(YOURSELF)"
    elsif (name = user.display_name)
      "#{name} <#{user.phone&.sanitized || user.lid}>"
    else
      "(UNKNOWN USER) <#{user.lid}>"
    end
  end

  sig { params(message: WhatsappMessage).returns(String) }
  def quoted_participant_identity(message)
    if (sender = message.quoted_message&.sender)
      whatsapp_user_identity(sender)
    elsif (jid = message.quoted_participant_jid)
      if jid == application_jid
        "(YOURSELF)"
      else
        "(UNKNOWN USER) <#{jid}>"
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
end
