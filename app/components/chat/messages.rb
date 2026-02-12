# typed: true
# frozen_string_literal: true

class Components::Chat::Messages < Components::Base
  # == Configuration ==

  register_value_helper :auto_link

  sig { params(messages: T::Array[WhatsappMessage]).void }
  def initialize(messages:)
    super()
    @messages = messages
  end

  # == Component ==

  sig { override.void }
  def view_template
    @messages.each do |message|
      li do
        render_message(message)
      end
    end
  end

  private

  # == Helpers ==

  sig { params(message: WhatsappMessage).void }
  def render_message(message)
    div(
      class: "chat_message group/message",
      data: {
        sender: ("you" if message.from_application_user?),
      },
    ) do
      # image_tag(message.sender!.profile_picture_url, class: "size-12 rounded-full")
      div(class: "chat_message_body") do
        unless message.from_application_user?
          div(class: "text-accent font-semibold") do
            sender_label(message)
          end
        end
        div(class: "flex items-end gap-x-2") do
          p(class: "wrap-break-word") { render_body(message) }
          local_time(
            message.timestamp,
            format: "%l:%M %p",
            class: "cursor-pointer",
            data: {
              controller: "clipboard tooltip",
              action: class_names(
                "click->clipboard#copy",
                "clipboard:copied->tooltip#flash",
              ),
              clipboard_copy_value: message.whatsapp_id,
              tooltip_trigger_value: "manual",
              tooltip_content_value: "copied WhatsApp message ID!",
              tooltip_flash_duration_value: 1400,
            },
          )
        end
      end
    end
  end

  sig { params(message: WhatsappMessage).void }
  def render_body(message)
    mentioned_users = message.mentioned_users.filter do |user|
      user.phone_mention_token.present?
    end
    if mentioned_users.empty?
      render_body_text(message.body)
      return
    end

    mentions_by_token = T.let({}, T::Hash[String, WhatsappUser])
    mentioned_users.each do |user|
      user.mention_tokens.each do |token|
        mentions_by_token[token] = user
      end
    end
    pattern = Regexp.union(mentions_by_token.keys)
    parts = message.body.split(/(#{pattern})/)

    parts.each do |part|
      if (user = mentions_by_token[part])
        href = if (phone = user.phone)
          "https://wa.me/#{phone.sanitized}"
        end
        a(class: "link font-bold", href:) do
          span(class: "text-muted-foreground") { "@" }
          if user.application_user?
            plain(Rails.configuration.x.site_name)
          else
            plain(
              user.display_name ||
                user.phone&.international(true) ||
                user.lid,
            )
          end
        end
      else
        render_body_text(part)
      end
    end
  end

  sig { params(text: String).void }
  def render_body_text(text)
    raw(auto_link(text, html: { class: "link" })) # rubocop:disable Rails/OutputSafety
  end

  sig { params(message: WhatsappMessage).returns(String) }
  def sender_label(message)
    sender = message.sender!
    sender.display_name ||
      sender.phone&.international(true) ||
      sender.lid
  end
end
