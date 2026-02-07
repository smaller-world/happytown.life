# typed: false
# frozen_string_literal: true

return unless Rails.env.production?

if (host = ENV["CANONICAL_HOST"])
  Rails.application.config.middleware.use(
    Rack::CanonicalHost,
    host,
    cache_control: "no-cache",
    if: ->(uri) {
      uri.host != "localhost" &&
        uri.host != "127.0.0.1" &&
        uri.host != "0.0.0.0"
    },
  )
end
