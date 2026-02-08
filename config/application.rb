# typed: true
# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HappyTown
  extend T::Sig

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(8.1)

    config.x.site_name = "happy town"
    config.x.site_tagline = "a home for third-space hosts and guests"
    config.x.site_description =
      "a new kind of third space in toronto. weekly walks, irl chat groups, " \
        "and hobby tables for curious, friendly people who like wandering " \
        "conversations."
    config.x.luma_url = "https://luma.com/happytown"
    config.x.instagram_url = "https://instagram.com/happytown.to"
    config.x.tiktok_url = "https://tiktok.com/@adamdriversbod"

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: ["assets", "tasks"])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end

  sig { returns(Wasenderapi) }
  def self.wasenderapi
    api_key = Rails.application.credentials.dig(:wasenderapi, :api_key) or
      raise "Missing WASenderAPI key"
    @wasenderapi ||= Wasenderapi.new(api_key:)
  end
end
