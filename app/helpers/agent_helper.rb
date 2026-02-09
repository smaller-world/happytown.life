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
    if (name = user.display_name)
      "#{name} <JID: #{user.lid})>"
    else
      "unknown whatsapp user <JID: #{user.lid}>"
    end
  end
end
