# typed: true
# frozen_string_literal: true

class Components::FieldGroup < Components::Base
  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    root_component(
      :div,
      class: "group/field-group",
      data: { slot: "field-group" },
      &block
    )
  end
end
