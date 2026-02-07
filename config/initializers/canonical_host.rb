# typed: false
# frozen_string_literal: true

canonical_host = ENV["CANONICAL_HOST"] or return

Rails.application.config.middleware.use(
  Rack::CanonicalHost,
  canonical_host,
  cache_control: "no-cache",
  if: ->(uri) {
    # Ignore local requests
    return false if uri.host.nil?
    return false if uri.host == "0.0.0.0" || uri.host == "::"

    ip_addr = IPAddr.new(uri.host)
    !ip_addr.loopback?
  },
)
