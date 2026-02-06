# typed: true
# frozen_string_literal: true

class Components::Badge < Components::Base
  sig { params(variant: Symbol, options: T.untyped).void }
  def initialize(variant: :default, **options)
    super(**options)
    @variant = variant
  end

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    root_component(
      :span,
      class: "group/badge",
      data: {
        slot: "badge",
        variant: @variant,
      },
      &block
    )
  end
end
