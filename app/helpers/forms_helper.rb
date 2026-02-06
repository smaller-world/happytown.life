# typed: true
# frozen_string_literal: true

module FormsHelper
  extend T::Sig
  extend T::Helpers

  requires_ancestor { ActionView::Base }
  requires_ancestor { ApplicationHelper }

  # == Methods ==

  sig do
    params(record: ActiveRecord::Base, attribute: Symbol)
      .returns(T.nilable(String))
  end
  def error_message_for(record, attribute)
    record.errors.messages_for(attribute).first
    # if (error = record.errors.messages_for(attribute).first)
    #   [ attribute.to_s.humanize(capitalize: false), error ].join(" ")
    # end
  end

  sig do
    params(hash: T::Hash[Symbol, T.untyped])
      .returns(T::Hash[Symbol, T.untyped])
  end
  def delete_field_wrapper_options_from(hash)
    delete_from(hash, :label, :description, :error)
  end

  sig { params(options: T::Hash[Symbol, T.untyped]).returns(T.nilable(String)) }
  def field_error_in(options)
    if options.key?(:error)
      options[:error]
    elsif (form = options[:form]) &&
        (field = options[:field]) &&
        form.is_a?(ActionView::Helpers::FormBuilder) &&
        (object = form.object)
      object.errors.messages_for(field).first
    end
  end
end
