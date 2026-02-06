# typed: true
# frozen_string_literal: true

class Views::Pages::Landing < Views::Base
  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    render Components::Layout do |layout|
      layout.page_container(
        class: "flex flex-col items-center justify-center gap-y-2",
      ) do
        render Components::Card.new(
          class: "w-full max-w-sm gap-y-4",
        ) do |card|
          div(class: "size-24 rounded-full self-center overflow-hidden") do
            image_tag(
              "logo-icon.png",
              class: "size-full object-contain scale-[1.2]",
            )
          end
          card.content(class: "flex flex-col items-center gap-y-2.5") do
            h1(class: "text-2xl font-bold text-center") do
              "welcome to happy town!"
            end
            render Components::Button.new(
              component: "a",
              href: home_path,
              variant: :outline,
              size: :lg,
            ) do
              Icon(
                "huge/arrow-right-02",
                class: "size-6",
                data: { icon: "inline-start" },
              )
              span(class: "text-lg") { "home" }
            end
          end
        end
      end
    end
  end
end
