# typed: true
# frozen_string_literal: true

class Views::Admin::Dashboard::Show < Views::Base
  sig { override.params(content: T.nilable(T.proc.void)).void }
  def view_template(&content)
    Components::Layout() do |layout|
      layout.page_container(class: "flex flex-col gap-y-4") do
        div do
          h1(class: "text-2xl font-bold") { "admin dashboard" }
          blockquote(class: "italic") do
            "“so ya wanna run for happy town major, is that right?”"
          end
        end
        div(class: "flex flex-col gap-y-1") do
          h2(class: "text-xl font-semibold") { "quick links" }
          ul(class: "list-disc ml-6 space-y-0.5 [&_a]:hover:underline") do
            li do
              link_to("webhook logs", [:admin, :webhook_messages])
            end
            li do
              link_to("mission control", [:mission_control, :jobs])
            end
          end
        end
      end
    end
  end
end
