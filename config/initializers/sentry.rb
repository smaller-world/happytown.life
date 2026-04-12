# typed: true
# frozen_string_literal: true

credentials = Rails.application.credentials.sentry

Sentry.init do |config|
  config.dsn = credentials&.dsn
  config.enabled_environments = [ "production" ]
  config.breadcrumbs_logger = [
    :sentry_logger,
    :active_support_logger,
    :http_logger,
  ]
  config.traces_sample_rate = 0.0
  config.excluded_exceptions += [
    "ActiveSupport::MessageVerifier::InvalidSignature",
    "ActiveRecord::RecordNotUnique",
  ]

  # Automatically attach to Rails error reporter
  config.rails.register_error_subscriber = true

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  config.before_send = lambda do |event, hint|
    if (exception = hint[:exception])
      case exception
      when Notion::BadResponse
        context = {
          code: exception.code,
          message: exception.message,
          request_id: exception.request_id,
          additional_data: exception.additional_data,
        }
        event.set_context("notion_api_error", context.compact)
      when Tally::BadResponse
        context = {
          error_type: exception.error_type,
        }
        event.set_context("tally_api_error", context.compact)
      end
    end
  end
end
