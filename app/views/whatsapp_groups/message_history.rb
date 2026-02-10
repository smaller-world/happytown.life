# typed: true
# frozen_string_literal: true

class Views::WhatsappGroups::MessageHistory < Views::Base
  include Phlex::Rails::Helpers::AssetPath

  # == Configuration ==

  sig { params(group: WhatsappGroup).void }
  def initialize(group:)
    super()
    @group = group
    @messages = group.messages.order(created_at: :asc).last(50)
  end

  # == View ==

  sig { override.params(content: T.nilable(T.proc.void)).void }
  def view_template(&content)
    Components::Layout(body_class: "max-h-dvh") do |layout|
      layout.page_container(class: "flex-1 min-h-0 flex flex-col gap-y-6") do
        Components::Chat(group: @group, messages: @messages)
      end
    end
  end
end
