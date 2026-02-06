# typed: true
# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  sig { params(user: User, token: String, options: T.untyped).void }
  def initialize(user:, token:, **options)
    super(**options)
    @user = user
    @token = token
  end

  # == Templates ==

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    render Components::Layout.new(title: "update password") do |layout|
      layout.page_container(
        class: "flex flex-col items-center justify-center",
      ) do
        render Components::Card.new(class: "w-full max-w-xs") do |card|
          card.header do
            card.title(class: "text-lg text-center") do
              "update your password"
            end
          end
          card.content do
            form_with(url: passwords_path(@token), method: :put) do |form|
              render Components::FieldGroup do
                render Components::Field.new(
                  form:,
                  field: :password,
                ) do |field|
                  field.label { "new password" }
                  render Components::Input.new(
                    form:,
                    field: :password,
                    type: :password,
                    autocomplete: "new-password",
                    required: true,
                    maxlength: 72,
                  )
                  field.error
                end

                render Components::Field.new(
                  form:,
                  field: :password,
                ) do |field|
                  field.label { "new password (again)" }
                  render Components::Input.new(
                    form:,
                    field: :password_confirmation,
                    type: :password,
                    autocomplete: "new-password",
                    required: true,
                    maxlength: 72,
                  )
                  field.error
                end

                render Components::Field do
                  render Components::Button.new(
                    type: :submit,
                    size: :lg,
                  ) do
                    Icon(
                      "huge/arrow-right-02",
                      class: "size-6",
                      data: { icon: "inline-start" },
                    )
                    span(class: "text-base") do
                      "update password"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
