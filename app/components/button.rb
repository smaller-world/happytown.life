# typed: true
# frozen_string_literal: true

class Components::Button < Components::Base
  sig { params(variant: Symbol, size: Symbol, options: T.untyped).void }
  def initialize(variant: :default, size: :default, **options)
    super(**options)
    @variant = variant
    @size = size
  end

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    root_component(
      :button,
      class: "group/button",
      data: {
        slot: "button",
        variant: @variant,
        size: @size,
      },
      &block
    )
  end
end
