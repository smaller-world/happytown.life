# typed: true
# frozen_string_literal: true

class Components::Input < Components::Base
  sig do
    params(
      form: T.nilable(Phlex::Rails::Builder),
      field: T.nilable(Symbol),
      options: T.untyped,
    ).void
  end
  def initialize(form:, field: nil, **options)
    super(**options)
    @form = form
    @field = field
  end

  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.bind(T.self_type).void)).void }
  def view_template(&block)
    if (form = @form) && (field = @field)
      id = form.send(:field_id, field)
      name = form.send(:field_name, field)
    end
    root_component(
      :input,
      id:,
      name:,
      data: { slot: "input" },
      &block
    )
  end
end
