# typed: true
# frozen_string_literal: true

class Views::Home::Show < Views::Base
  sig { override.params(content: T.nilable(T.proc.void)).void }
  def view_template(&content)
    Components::Layout() do |layout|
      layout.page_container do
        "hi"
      end
    end
  end
end
