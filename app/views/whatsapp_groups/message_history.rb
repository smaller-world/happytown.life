# typed: true
# frozen_string_literal: true

class Views::WhatsappGroups::MessageHistory < Views::Base
  include Phlex::Rails::Helpers::AssetPath

  # == Configuration ==

  sig do
    params(
      group: WhatsappGroup,
      # messages: T::Enumerable[WhatsappMessage],
      # pagy: Pagy::Offset,
    ).void
  end
  def initialize(group:)
    super()
    @group = group
    @messages = group.messages.order(created_at: :asc).last(50)
    # @pagy = pagy
  end

  # == View ==

  sig { override.params(content: T.nilable(T.proc.void)).void }
  def view_template(&content)
    Components::Layout() do |layout|
      layout.page_container(class: "flex-1 flex flex-col gap-y-6") do
        Components::Card(size: :sm, class: "chat_card") do |card|
          card.header(class: "flex items-center gap-x-3 bg-background") do
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
          card.content(class: "chat_card_content") do
            ul(class: "space-y-2") do
              @messages.each do |message|
                li do
                  render_chat_message(message)
                end
              end
            end
          end
        end
      end
    end
  end

  private

  # == Helpers ==

  sig { params(message: WhatsappMessage).void }
  def render_chat_message(message)
    div(class: "flex items-end gap-x-2") do
      # image_tag(message.sender!.profile_picture_url, class: "size-12 rounded-full")
      div(class: "chat_message_body") do
        div(class: "text-accent font-semibold") do
          sender = message.sender!
          sender.display_name ||
            sender.phone&.international(true) ||
            sender.lid
        end
        div(class: "flex items-end gap-x-2") do
          p(class: "wrap-break-word") { message.body }
          local_time(message.timestamp, format: "%l:%M %p")
        end
      end
    end
  end
end
