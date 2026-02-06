# typed: true
# frozen_string_literal: true

class Components::Base < Phlex::HTML
  extend T::Sig
  extend T::Helpers

  abstract!

  # == View Helpers ==

  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ClassNames
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::FormWith
  include PhlexIcons

  # == Initializer ==

  sig { params(options: T.untyped).void }
  def initialize(**options)
    super()
    @options = options
  end

  # == Templates ==

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end

  sig do
    abstract.params(block: T.nilable(T.proc.bind(T.self_type).void)).void
  end
  def view_template(&block); end

  private

  # == Helpers ==

  sig do
    params(
      default: Symbol,
      options: T.untyped,
      block: T.nilable(T.proc.bind(T.self_type).void),
    ).void
  end
  def root_component(default, **options, &block)
    component = @options.delete(:component) || default
    class_override = @options.delete(:class)
    class_option = options.delete(:class)

    data = options.delete(:data) || {}
    if (data_override = @options.delete(:data))
      data.merge!(data_override)
    end
    data.compact!

    aria = options.delete(:aria) || {}
    if (aria_override = @options.delete(:aria))
      aria.merge!(aria_override)
    end
    aria.compact!

    send(
      component,
      class: class_names(class_option, class_override),
      data:,
      aria:,
      **options,
      **@options,
      &block
    )
  end
end
