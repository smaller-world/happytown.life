# Sentry Ruby: Adding Structured Fields to Errors

## Research Date
April 12, 2026

## Summary

The Sentry Ruby SDK provides several mechanisms for adding structured context and data to captured errors. This doc covers the primary approaches.

---

## 1. Custom Contexts (`set_context`) — **Recommended Approach**

This is the **best way** to attach arbitrary structured data to events. Contexts are viewable on the issue page in Sentry's UI.

### Usage

```ruby
# Global scope — applies to all future events
Sentry.configure_scope do |scope|
  scope.set_context(
    'my_custom_data',
    {
      user_id: 123,
      tenant: 'acme',
      feature_flag: 'new_checkout'
    }
  )
end

# Local scope — applies only to events within this block
Sentry.with_scope do |scope|
  scope.set_context('request_details', { path: '/checkout', method: 'POST' })
  Sentry.capture_exception(exception)
end
```

### Constraints
- Context name: no restrictions (freeform string)
- Context object keys: all allowed **except** `type` (reserved internally)
- Must always be an object/hash (not a primitive)
- **Not searchable** in Sentry's UI — use tags if you need searchability
- Sentry may trim large contexts to stay within payload limits

---

## 2. Tags (`set_tags`) — For Searchable Data

Tags are key/value **string** pairs that are both **indexed and searchable** in Sentry's UI. They power filters, tag-distribution maps, and help you quickly find related events.

### Usage

```ruby
# Set tags on the current scope
Sentry.set_tags('page.locale': 'de-at')
Sentry.set_tags(environment: 'production', feature: 'checkout')

# Set tags when capturing an exception
Sentry.with_scope do |scope|
  scope.set_tags(tenant: 'acme', plan: 'premium')
  Sentry.capture_exception(exception)
end
```

### Constraints
- **Tag keys**: max 32 chars; only letters (`a-zA-Z`), numbers (`0-9`), underscores (`_`), periods (`.`), colons (`:`), and dashes (`-`)
- **Tag values**: max 200 chars; cannot contain newline (`\n`)
- Values are **strings only**
- **Searchable** in Sentry queries

---

## 3. Event Processors — For Programmatic Enrichment

Event processors let you hook into the event pipeline and mutate events before they're sent. Useful for adding context that depends on runtime state.

### Usage

```ruby
# Global event processor — runs on every event
Sentry.add_global_event_processor do |event, hint|
  event.tags ||= {}
  event.tags['app.version'] = MyApp::VERSION
  event.tags['deploy.sha'] = ENV['HEROKU_SLUG_COMMIT']
  event
end

# Scope-level event processor — runs only for events in this scope
Sentry.with_scope do |scope|
  scope.add_event_processor do |event, hint|
    event.set_context('request_metadata', {
      request_id: hint[:request]&.request_id,
      ip: hint[:request]&.remote_ip
    })
    event
  end

  Sentry.capture_exception(exception)
end
```

### Key Differences from `before_send`
- Event processors run in **undetermined order** (unlike `before_send` which runs last)
- Scope-level processors only run on events captured **while that scope is active**
- `before_send` / `before_send_transaction` are **global** and **always run last**

---

## 4. `before_send` Hook — Final Modification Point

Provides a lambda/proc called with the event object right before it's sent. This is the **last chance** to modify or drop an event.

### Usage

```ruby
Sentry.init do |config|
  config.before_send = lambda do |event, hint|
    # hint[:exception] gives you the original exception
    if hint[:exception].is_a?(MyCustomError)
      event.set_context('custom_error_data', {
        error_code: hint[:exception].code,
        user_input: hint[:exception].user_input
      })
    end
    event
  end
end
```

---

## 5. Capturing Exceptions with Scope

The most common pattern for adding structured data to a specific error:

```ruby
begin
  do_something_risky
rescue SomeError => exception
  Sentry.with_scope do |scope|
    scope.set_context('payment', {
      amount: order.total,
      currency: order.currency,
      provider: payment_provider.name
    })
    scope.set_tags(payment_method: order.payment_method)
    Sentry.capture_exception(exception)
  end
end
```

---

## Recommendation: Contexts vs Tags

| Use Case | Mechanism | Searchable? | Value Types |
|----------|-----------|-------------|-------------|
| Debugging context (objects, nested data) | `set_context` | No | Any (hash/object) |
| Filtering, dashboards, grouping | `set_tags` | Yes | Strings only |
| Programmatic enrichment | Event processors / `before_send` | Depends | Any |

**Best practice**: Use `set_context` for rich structured data (objects, nested values) and `set_tags` for flat string key/value pairs you want to filter/search by in the UI.

---

## Deprecated: `set_extra`

The older `set_extra` method for "Additional Data" is **deprecated** in favor of structured contexts. New code should use `set_context` instead.

---

## Sources

- https://docs.sentry.io/platforms/ruby/context/
- https://docs.sentry.io/platforms/ruby/enriching-events/
- https://docs.sentry.io/platforms/ruby/enriching-events/event-processors/
- https://docs.sentry.io/platforms/ruby/enriching-events/tags/
- https://docs.sentry.io/platforms/ruby/configuration/options/
- https://docs.sentry.io/platforms/ruby/usage/
