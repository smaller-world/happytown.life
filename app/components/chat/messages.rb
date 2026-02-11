# typed: true
# frozen_string_literal: true

class Components::Chat::Messages < Components::Base
  # == Configuration ==

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
        div(
          class: "chat_message group/message",
          data: {
            sender: ("you" if message.from_application?),
          },
        ) do
          # image_tag(message.sender!.profile_picture_url, class: "size-12 rounded-full")
          div(class: "chat_message_body") do
            unless message.from_application?
              div(class: "text-accent font-semibold") do
                sender_label(message)
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
  end

  private

  # == Helpers ==

  sig { params(message: WhatsappMessage).returns(String) }
  def sender_label(message)
    sender = message.sender!
    sender.display_name ||
      sender.phone&.international(true) ||
      sender.lid
  end
end
