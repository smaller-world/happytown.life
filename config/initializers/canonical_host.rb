# typed: false
# frozen_string_literal: true

return unless Rails.env.production?

if (host = ENV["CANONICAL_HOST"])
  Rails.application.config.middleware.use(Rack::CanonicalHost, host)
end
