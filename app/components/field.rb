# typed: true
# frozen_string_literal: true

class Components::Field < Components::Base
  sig do
    params(
      form: T.nilable(Phlex::Rails::Builder),
      field: T.nilable(Symbol),
      orientation: Symbol,
      invalid: T::Boolean,
      options: T.untyped,
    ).void
  end
  def initialize(
    form: nil,
    field: nil,
    orientation: :vertical,
    invalid: false,
    **options
  )
    super(**options)
    @form = form
    @field = field
    @orientation = orientation
    @invalid = invalid
  end

  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    data = {
      slot: "field",
      orientation: @orientation,
    }
    if invalid?
      data[:invalid] = true
    end
    root_component(:div, role: "group", class: "group/field", data:, &block)
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def content(**options, &block)
    class_option = options.delete(:class)
    div_with_slot(
      "field-content",
      class: class_names("group/field-content", class_option),
      **options,
      &block
    )
  end

  sig { params(options: T.untyped, block: T.nilable(T.proc.bind(T.self_type).void)).void }
  def label(**options, &block)
    class_option = options.delete(:class)
    label_class = class_names("group/field-label peer/field-label", class_option)
    data = options.delete(:data) || {}
    data[:slot] = "field-label"
    options[:class] = label_class
    options[:data] = data
    if (form = @form) && (field = @field)
      form.send(:label, field, **options, &block)
    else
      label(**options, &block)
    end
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def title(**options, &block)
    div_with_slot("field-title", **options, &block)
  end

  sig { params(options: T.untyped, block: T.proc.bind(T.self_type).void).void }
  def description(**options, &block)
    data = options.delete(:data) || {}
    data[:slot] = "field-description"
    p(data:, **options, &block)
  end

  sig { params(options: T.untyped, block: T.nilable(T.proc.bind(T.self_type).void)).void }
  def separator(**options, &block)
    data = options.delete(:data) || {}
    data[:content] = block_given?
    div_with_slot("field-separator", data:, **options) do
      render Components::Separator.new(class: "absolute inset-0 top-1/2")
      if block_given?
        span(data: { slot: "field-separator-content" }, &block)
      end
    end
  end

  sig { params(errors: T.nilable(T::Array[String]), options: T.untyped, block: T.nilable(T.proc.bind(T.self_type).void)).void }
  def error(errors: error_messages, **options, &block)
    return if block.nil? && errors.blank?

    div(role: "alert", data: { slot: "field-error" }, **options) do
      if block_given?
        yield
      elsif (errors = errors.presence)
        if errors.length == 1
          errors.first
        else
          ul(class: "ml-4 flex list-disc flex-col gap-1") do
            errors.each do |msg|
              li { msg }
            end
          end
        end
      end
    end
  end

  # == Helpers ==

  sig { returns(T.nilable(String)) }
  def id
    if (form = @form) && (field = @field)
      form.send(:field_id, field)
    end
  end

  sig { returns(T.nilable(T::Array[String])) }
  def error_messages
    if (record = @form&.send(:object)) && (field = @field)
      record.errors.messages_for(field)
    end
  end

  sig { returns(T::Boolean) }
  def invalid?
    @invalid || error_messages.present?
  end

  private

  # == Helpers ==

  def div_with_slot(slot, **options, &block)
    data = options.delete(:data) || {}
    data[:slot] = slot
    div(data:, **options, &block)
  end
end
