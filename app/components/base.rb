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

  sig { params(element: T.nilable(Symbol), attributes: T.untyped).void }
  def initialize(element: nil, **attributes)
    super()
    @element = element
    @attributes = attributes
  end

  # == Component ==

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end

  sig do
    abstract.params(content: T.nilable(T.proc.void)).void
  end
  def view_template(&content); end

  private

  # == Helpers ==

  sig do
    params(
      default_element: Symbol,
      attributes: T.untyped,
      content: T.nilable(T.proc.void),
    ).void
  end
  def root_element(default_element, **attributes, &content)
    send(@element || default_element, **mix(attributes, @attributes), &content)
  end
end
