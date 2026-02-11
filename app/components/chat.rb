# typed: true
# frozen_string_literal: true

class Components::Chat < Components::Base
  sig do
    params(
      group: WhatsappGroup,
      messages: T::Array[WhatsappMessage],
      attributes: T.untyped,
    ).void
  end
  def initialize(group:, messages: [], **attributes)
    super(**attributes)
    @group = group
    @messages = messages
  end

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    Components::Card(
      size: :sm,
      **mix({ class: "chat_card" }, @attributes),
    ) do |card|
      card.header(class: "flex items-center gap-x-3") do
        if (url = @group.profile_picture_url)
          image_tag(url, class: "size-12 rounded-full")
        end
        div(class: "flex flex-col gap-y-1") do
          card.title(class: "text-2xl font-bold") do
            @group.subject
          end
          if (description = @group.description)
            card.description { description }
          end
        end
      end
      card.content(
        class: "chat_card_content",
        data: {
          controller: "scroll-to-bottom",
        },
      ) do
        ul(id: "whatsapp_messages", class: "chat_messages") do
          @messages.each do |message|
            li do
              render_message(message)
            end
          end
        end
        div(class: "chat_empty_indicator") do
          p(class: "text-muted-foreground text-sm") do
            "no messages found 😪"
          end
        end
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
        sender: ("application" if message.from_application?),
      },
    ) do
      # image_tag(message.sender!.profile_picture_url, class: "size-12 rounded-full")
      div(class: "chat_message_body") do
        unless message.from_application?
          div(class: "text-accent font-semibold") do
            sender = message.sender!
            sender.display_name ||
              sender.phone&.international(true) ||
              sender.lid
          end
        end
        div(class: "flex items-end gap-x-2") do
          p(class: "wrap-break-word") { message.body }
          local_time(message.timestamp, format: "%l:%M %p")
        end
      end
    end
  end
end
