# typed: true
# frozen_string_literal: true

class Views::Homes::Show < Views::Base
  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    render Components::Layout do |layout|
      layout.page_container do
        "hi"
      end
    end
  end
end
