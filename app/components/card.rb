# typed: true
# frozen_string_literal: true

class Components::Card < Components::Base
  sig { params(size: Symbol, options: T.untyped).void }
  def initialize(size: :default, **options)
    super(**options)
    @size = size
  end

  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    root_component(
      :div,
      class: "group/card",
      data: {
        slot: "card",
        size: @size,
      },
      &block
    )
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def header(**options, &block)
    class_option = options.delete(:class)
    div_with_slot(
      "card-header",
      class: class_names("group/card-header", class_option),
      **options,
      &block
    )
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def title(**options, &block)
    div_with_slot("card-title", **options, &block)
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def description(**options, &block)
    div_with_slot("card-description", **options, &block)
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def action(**options, &block)
    div_with_slot("card-action", **options, &block)
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def content(**options, &block)
    div_with_slot("card-content", **options, &block)
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def footer(**options, &block)
    div_with_slot("card-footer", **options, &block)
  end

  private

  # == Helpers ==
  def div_with_slot(slot, **options, &block)
    data = options.delete(:data) || {}
    data[:slot] = slot
    div(data:, **options, &block)
  end
end
