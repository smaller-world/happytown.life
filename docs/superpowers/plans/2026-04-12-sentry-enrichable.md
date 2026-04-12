# SentryEnrichable Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a `SentryEnrichable` module that lets exception classes opt into structured Sentry context, wire it into the Sentry `before_send` hook, and apply it to `Notion::BadResponse` — while also removing now-redundant top-level `require` calls from autoloaded `lib/*.rb` files.

**Architecture:** A plain Ruby module `lib/sentry_enrichable.rb` defines a two-method protocol (`sentry_context`, `sentry_tags`). `Notion::BadResponse` includes it and implements `sentry_context` using Notion's structured error body. The Sentry initializer gains a `before_send` hook that calls the protocol on any exception that responds to it. Top-level `require "rails"` / `require "http"` in `lib/*.rb` are removed because Rails autoloads the file, so those constants are already available.

**Tech Stack:** Ruby, Sorbet (`T::Sig`), Sentry Ruby SDK (`before_send` hook), http.rb

---

### Task 1: Remove redundant requires from autoloaded lib files

`lib/*.rb` files at the first level are autoloaded by Rails (`config.autoload_lib`). Top-level `require "rails"` and `require "http"` in those files are unnecessary and will be removed.

Files to modify:
- `lib/luma.rb` — remove lines 4–5 (`require "rails"`, `require "http"`)
- `lib/wa_sender_api.rb` — remove lines 4–5 (`require "rails"`, `require "http"`)
- `lib/tally.rb` — remove lines 4–5 (`require "rails"`, `require "http"`)
- `lib/notion.rb` — remove lines 4–5 (`require "rails"`, `require "http"`)
- `lib/springaling.rb` — remove line 4 (`require "rails"`)
- `lib/tagged_logging.rb` — remove lines 4–5 (`require "sorbet-runtime"`, `require "rails"`)

Do NOT touch files under `lib/extensions/` or `lib/tasks/` — those are not autoloaded.

- [ ] **Step 1: Remove requires from lib/luma.rb**

Delete these two lines from `lib/luma.rb`:
```ruby
require "rails"
require "http"
```
The file should start with `# typed: true` / `# frozen_string_literal: true` / blank line / `class Luma`.

- [ ] **Step 2: Remove requires from lib/wa_sender_api.rb**

Delete these two lines from `lib/wa_sender_api.rb`:
```ruby
require "rails"
require "http"
```

- [ ] **Step 3: Remove requires from lib/tally.rb**

Delete these two lines from `lib/tally.rb`:
```ruby
require "rails"
require "http"
```

- [ ] **Step 4: Remove requires from lib/notion.rb**

Delete these two lines from `lib/notion.rb`:
```ruby
require "rails"
require "http"
```

- [ ] **Step 5: Remove requires from lib/springaling.rb**

Delete this line from `lib/springaling.rb`:
```ruby
require "rails"
```

- [ ] **Step 6: Remove requires from lib/tagged_logging.rb**

Delete these two lines from `lib/tagged_logging.rb`:
```ruby
require "sorbet-runtime"
require "rails"
```

- [ ] **Step 7: Boot the app to verify nothing is broken**

```bash
mise x -- bin/rails runner "puts 'ok'"
```

Expected: `ok` with no load errors.

- [ ] **Step 8: Commit**

```bash
git add lib/luma.rb lib/wa_sender_api.rb lib/tally.rb lib/notion.rb lib/springaling.rb lib/tagged_logging.rb
git commit -m "Remove redundant requires from autoloaded lib files"
```

---

### Task 2: Create lib/sentry_enrichable.rb

Create the module that defines the opt-in protocol. Every method has a default no-op implementation so including classes only override what they need.

- [ ] **Step 1: Create lib/sentry_enrichable.rb**

```ruby
# typed: true
# frozen_string_literal: true

module SentryEnrichable
  extend T::Sig
  extend T::Helpers

  requires_ancestor { Exception }

  # Override to attach a structured context hash to the Sentry event.
  # The hash is passed to `Sentry::Scope#set_context` under the key "api_error".
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def sentry_context
    {}
  end

  # Override to attach searchable string tags to the Sentry event.
  # The hash is passed to `Sentry::Scope#set_tags`.
  sig { returns(T::Hash[String, String]) }
  def sentry_tags
    {}
  end
end
```

- [ ] **Step 2: Boot the app to verify autoload works**

```bash
mise x -- bin/rails runner "puts SentryEnrichable"
```

Expected: `SentryEnrichable`

- [ ] **Step 3: Commit**

```bash
git add lib/sentry_enrichable.rb
git commit -m "Add SentryEnrichable protocol module"
```

---

### Task 3: Wire SentryEnrichable into the Sentry before_send hook

Edit `config/initializers/sentry.rb` to add a `before_send` block that reads `sentry_context` and `sentry_tags` from any exception that includes the protocol.

- [ ] **Step 1: Edit config/initializers/sentry.rb**

The current file:
```ruby
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
end
```

Add the `before_send` block inside `Sentry.init` after `config.send_default_pii = true`:

```ruby
  config.before_send = lambda do |event, hint|
    exception = hint[:exception]
    if exception.respond_to?(:sentry_context)
      context = exception.sentry_context
      event.set_context("api_error", context) if context.any?
    end
    if exception.respond_to?(:sentry_tags)
      tags = exception.sentry_tags
      event.tags.merge!(tags) if tags.any?
    end
    event
  end
```

- [ ] **Step 2: Boot to confirm the initializer loads**

```bash
mise x -- bin/rails runner "puts Sentry.configuration.before_send.nil? ? 'missing' : 'ok'"
```

Expected: `ok`

- [ ] **Step 3: Commit**

```bash
git add config/initializers/sentry.rb
git commit -m "Wire SentryEnrichable protocol into Sentry before_send hook"
```

---

### Task 4: Implement SentryEnrichable on Notion::BadResponse

Update `lib/notion.rb` so that `Notion::BadResponse`:

1. Includes `SentryEnrichable`
2. Parses the structured Notion error body (`object`, `status`, `code`, `message`, `request_id`)
3. Exposes `http_status`, `error_code`, `error_message`, `request_id` as accessors
4. Sets a human-readable message: `"Notion API error (code): message"` — http status accessible via accessor, not embedded in string
5. Implements `sentry_context` returning a rich hash for the Sentry "api_error" context

The Notion error body shape (from research):
```json
{
  "object": "error",
  "status": 400,
  "code": "validation_error",
  "message": "body failed validation: ...",
  "request_id": "abc-123",
  "additional_data": {}
}
```

- [ ] **Step 1: Update Notion::BadResponse in lib/notion.rb**

Replace the current `BadResponse` class:
```ruby
class BadResponse < StandardError
  extend T::Sig

  sig { params(response: HTTP::Response).void }
  def initialize(response)
    @response = response
    super("Notion API error (status #{response.code}): #{response.parse}")
  end

  sig { returns(HTTP::Response) }
  attr_reader :response
end
```

With:
```ruby
class BadResponse < Error
  extend T::Sig
  include SentryEnrichable

  sig { params(response: HTTP::Response).void }
  def initialize(response)
    @response = response
    body = T.let(response.parse, T.untyped)
    @http_status = T.let(response.code, Integer)
    @error_code = T.let(body.is_a?(Hash) ? body["code"] : nil, T.nilable(String))
    @error_message = T.let(body.is_a?(Hash) ? body["message"] : nil, T.nilable(String))
    @request_id = T.let(body.is_a?(Hash) ? body["request_id"] : nil, T.nilable(String))
    super("Notion API error (#{@error_code}): #{@error_message}")
  end

  sig { returns(HTTP::Response) }
  attr_reader :response

  sig { returns(Integer) }
  attr_reader :http_status

  sig { returns(T.nilable(String)) }
  attr_reader :error_code

  sig { returns(T.nilable(String)) }
  attr_reader :error_message

  sig { returns(T.nilable(String)) }
  attr_reader :request_id

  sig { override.returns(T::Hash[Symbol, T.untyped]) }
  def sentry_context
    {
      http_status:,
      error_code:,
      error_message:,
      request_id:,
    }.compact
  end
end
```

- [ ] **Step 2: Boot to confirm no load errors**

```bash
mise x -- bin/rails runner "puts Notion::BadResponse.ancestors.include?(SentryEnrichable)"
```

Expected: `true`

- [ ] **Step 3: Commit**

```bash
git add lib/notion.rb
git commit -m "Implement SentryEnrichable on Notion::BadResponse with structured error fields"
```

---

## Self-review

**Spec coverage:**
- `lib/sentry_enrichable.rb` with `sentry_context` / `sentry_tags` stubs — Task 2 ✓
- Notion error format `"Notion API error (code): body"` — Task 4 ✓
- HTTP status accessible via accessor, not in message string — Task 4 (`http_status`) ✓
- `sentry_context` on Notion errors — Task 4 ✓
- No `sentry_tags` on Notion errors (tags stub stays on module only) — Task 4 ✓
- Remove top-level requires from `lib/*.rb` (first level only) — Task 1 ✓
- `before_send` hook wiring — Task 3 ✓

**Placeholder scan:** No TBDs. All code blocks are complete.

**Type consistency:** `sentry_context` returns `T::Hash[Symbol, T.untyped]` in both the module definition (Task 2) and the override (Task 4). `sentry_tags` returns `T::Hash[String, String]` in the module; not overridden in Notion (correct per spec).
