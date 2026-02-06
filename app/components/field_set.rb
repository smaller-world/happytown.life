# typed: true
# frozen_string_literal: true

class Components::FieldSet < Components::Base
  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    root_component(
      :div,
      data: { slot: "field-set" },
      &block
    )
  end

  sig do
    params(
      variant: Symbol,
      options: T.untyped,
      block: T.proc.bind(T.self_type).void,
    ).void
  end
  def legend(variant: :legend, **options, &block)
    data = options.delete(:data) || {}
    data[:slot] = "field-legend"
    data[:variant] = :legend
    legend(data:, **options, &block)
  end
end
