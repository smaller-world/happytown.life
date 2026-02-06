# typed: true
# frozen_string_literal: true

class ApplicationCable::Connection
  sig { params(value: T.nilable(User)).returns(T.nilable(User)) }
  def current_user=(value)
  end

  sig { returns(T.nilable(User)) }
  def current_user; end
end

class User
  class << self
    sig { params(token: String).returns(T.nilable(User)) }
    def find_by_password_reset_token(token: String); end

    sig { params(token: String).returns(User) }
    def find_by_password_reset_token!(token: String); end
  end
end
