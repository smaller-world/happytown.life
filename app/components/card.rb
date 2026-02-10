# typed: true
# frozen_string_literal: true

class Components::Card < Components::Base
  sig { params(size: Symbol, attributes: T.untyped).void }
  def initialize(size: :default, **attributes)
    super(**attributes)
    @size = size
  end

  # == Component ==

  sig { override.params(content: T.nilable(T.proc.void)).void }
  def view_template(&content)
    root_element(
      :div,
      class: "group/card",
      data: {
        slot: "card",
        size: @size,
      },
      &content
    )
  end

  sig { params(attributes: T.untyped, content: T.nilable(T.proc.void)).void }
  def header(**attributes, &content)
    div_with_slot("card-header", **attributes, &content)
  end

  sig { params(attributes: T.untyped, content: T.nilable(T.proc.void)).void }
  def title(**attributes, &content)
    div_with_slot("card-title", **attributes, &content)
  end

  sig { params(attributes: T.untyped, content: T.nilable(T.proc.void)).void }
  def description(**attributes, &content)
    div_with_slot("card-description", **attributes, &content)
  end

  sig { params(attributes: T.untyped, content: T.nilable(T.proc.void)).void }
  def action(**attributes, &content)
    div_with_slot("card-action", **attributes, &content)
  end

  sig { params(attributes: T.untyped, content: T.nilable(T.proc.void)).void }
  def content(**attributes, &content)
    div_with_slot("card-content", **attributes, &content)
  end

  sig { params(attributes: T.untyped, content: T.nilable(T.proc.void)).void }
  def footer(**attributes, &content)
    div_with_slot("card-footer", **attributes, &content)
  end

  private

  # == Helpers ==
  sig do
    params(
      slot: String,
      attributes: T.untyped,
      content: T.nilable(T.proc.void),
    ).void
  end
  def div_with_slot(slot, **attributes, &content)
    div(**mix({ data: { slot: } }, **attributes), &content)
  end
end
