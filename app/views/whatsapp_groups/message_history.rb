# typed: true
# frozen_string_literal: true

class Views::WhatsappGroups::MessageHistory < Views::Base
  # == Configuration ==

  sig do
    params(
      group: WhatsappGroup,
      messages: T::Enumerable[WebhookMessage],
      pagy: Pagy::Offset,
    ).void
  end
  def initialize(group:, messages:, pagy:)
    super()
    @group = group
    @messages = messages
    @pagy = pagy
  end

  # == View ==

  sig { override.params(content: T.nilable(T.proc.void)).void }
  def view_template(&content)
    Components::Layout() do |layout|
      layout.page_container(class: "flex flex-col gap-y-4") do
        Components::Card() do |card|
          card.content do
            if (url = @group.profile_picture_url)
              image_tag(url, class: "size-12 rounded-full")
            end
            h1(class: "text-xl font-bold") { @group.subject }
          end
        end
      end
    end
  end
end
