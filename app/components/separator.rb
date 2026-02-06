# typed: true
# frozen_string_literal: true

class Components::Separator < Components::Base
  sig { params(orientation: Symbol, decorative: T::Boolean, options: T.untyped).void }
  def initialize(orientation: :horizontal, decorative: true, **options)
    super(**options)
    @orientation = orientation
    @decorative = decorative
  end

  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    root_component(
      :div,
      role: (@decorative ? "none" : "separator"),
      data: {
        slot: "separator",
        orientation: @orientation,
      },
      aria: {
        orientation: (:vertical if @decorative && @orientation == :vertical),
      },
      &block
    )
  end
end
