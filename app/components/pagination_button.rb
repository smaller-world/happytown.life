# typed: true
# frozen_string_literal: true

class Components::PaginationButton < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  # == Configuration ==

  sig do
    params(
      to: T.untyped,
      pagy: T.nilable(Pagy),
      variant: Symbol,
      size: Symbol,
      click_on_appear: T::Boolean,
      form_class: T.nilable(String),
      form: T::Hash[Symbol, T.untyped],
      options: T.untyped,
    ).void
  end
  def initialize(
    to:,
    pagy: nil,
    variant: :default,
    size: :default,
    click_on_appear: false,
    form_class: nil,
    form: {},
    **options
  )
    super()
    @to = to
    @pagy = pagy
    @variant = variant
    @size = size
    @click_on_appear = click_on_appear
    @form_options = T.let(
      mix(form, { class: form_class }),
      T::Hash[Symbol, T.untyped],
    )
    @options = options
  end

  # == Component ==

  sig { override(allow_incompatible: true).params(content: T.proc.void).void }
  def view_template(&content)
    action = if @click_on_appear
      "click-on-appear:appear->click-on-appear#click"
    end
    button_to(
      @to,
      mix(
        {
          form: mix(
            {
              id: "pagination",
              class: "pagination_button",
              data: {
                turbo_stream: true,
              },
            },
            @form_options,
          ),
          params: {
            page: @pagy&.next,
          }.compact,
          class: "group/button",
          data: {
            slot: "button",
            variant: @variant,
            size: @size,
            controller: "click-on-appear",
            action:,
          },
        },
        @options,
      ),
      &content
    )
  end
end
