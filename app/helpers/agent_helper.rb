# typed: true
# frozen_string_literal: true

module AgentHelper
  extend T::Sig
  extend T::Helpers

  requires_ancestor { Kernel }

  # == Configuration ==

  include WhatsappMessaging

  # == Methods ==

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
    elsif (body = message.quoted_message_body)
      mentioned_users_in(
        body,
        scope: WhatsappUser
          .joins(:group_memberships)
          .where(whatsapp_group_memberships: { group_id: message.group_id }),
      ).map do |user|
        lid = user.lid.delete_suffix("@lid")
        body.gsub!("@#{lid}", "@#{whatsapp_user_identity(user)}")
      end
      body
    end
  end

  sig do
    params(text: String, scope: WhatsappUser::PrivateRelation)
      .returns(T::Array[WhatsappUser])
  end
  def mentioned_users_in(text, scope: WhatsappUser.all)
    mentions = text.scan(/@(\d+)/).flatten
    mentioned_numbers = mentions.map do |mention|
      phone = Phonelib.parse(mention.delete_prefix("@"))
      phone.to_s
    end
    scope.where(phone_number: mentioned_numbers).distinct.to_a
  end
end
