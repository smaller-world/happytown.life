# Springaling Tally-to-Notion Import — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import new Tally form submissions into a Notion data source via a
background job, using Notion itself as the sync cursor.

**Architecture:** Two thin HTTP clients (`lib/tally.rb`, `lib/notion.rb`)
modeled after the existing `lib/luma.rb`. A background job
(`Springaling::ImportTallySubmissionsJob`) orchestrates the sync: query Notion
for the last-imported submission ID, fetch new Tally submissions after that
cursor, create Notion pages for each. A config module
(`app/models/springaling.rb`) holds credential accessors.

**Tech Stack:** Ruby on Rails 8.1, http.rb, Sorbet, SolidQueue

**Spec:**
`docs/superpowers/specs/2026-04-11-springaling-tally-to-notion-import-design.md`

**Reference docs:**

- Tally API: `docs/research/tally_api.md`
- Notion API: `docs/research/notion_api.md`

**No tests in this plan.** The spec explicitly excludes testing (matches the bar
set by existing `lib/luma.rb` and `lib/wa_sender_api.rb`).

---

## File Map

| Action | File                                                   | Responsibility                                          |
| ------ | ------------------------------------------------------ | ------------------------------------------------------- |
| Create | `lib/tally.rb`                                         | Tally HTTP client (list form submissions)               |
| Create | `lib/notion.rb`                                        | Notion HTTP client (query data source, create page)     |
| Create | `app/models/springaling.rb`                            | Config accessors + stubbed property-mapping method      |
| Modify | `app/jobs/springaling/import_tally_submissions_job.rb` | Job that orchestrates the Tally → Notion sync           |
| Modify | `config/application.rb`                                | Add `#tally` and `#notion` singletons + class accessors |

---

### Task 1: Create the Tally HTTP client

**Files:**

- Create: `lib/tally.rb`

**Reference:** `docs/research/tally_api.md` — response shapes, pagination, and
field types. **Pattern to follow:** `lib/luma.rb` — same structure for
initializer, HTTP session setup, exception hierarchy, private helpers, and
`T::Struct` types.

- [ ] **Step 1: Create `lib/tally.rb`**

```ruby
# typed: true
# frozen_string_literal: true

require "rails"
require "http"

class Tally
  extend T::Sig

  # == Models ==

  class Question < T::Struct
    const :key, String
    const :label, String
    const :type, String
  end

  class Field < T::Struct
    const :key, String
    const :label, String
    const :type, String
    const :value, T.untyped
  end

  class Submission < T::Struct
    const :submission_id, String
    const :response_id, String
    const :respondent_id, String
    const :form_id, String
    const :created_at, ActiveSupport::TimeWithZone
    const :fields, T::Array[Field]
  end

  class ListSubmissionsResponse < T::Struct
    const :page, Integer
    const :limit, Integer
    const :has_more, T::Boolean
    const :questions, T::Array[Question]
    const :submissions, T::Array[Submission]
  end

  # == Exceptions ==

  class Error < StandardError; end

  class BadResponse < StandardError
    extend T::Sig

    sig { params(response: HTTP::Response).void }
    def initialize(response)
      @response = response
      super("Tally API error (status #{response.code}): #{response.parse}")
    end

    sig { returns(HTTP::Response) }
    attr_reader :response
  end

  class TooManyRequests < BadResponse; end

  # == Configuration ==

  sig { params(api_key: String).void }
  def initialize(api_key:)
    @session = T.let(
      HTTP
        .use(logging: { logger: Rails.logger.tagged(self.class.name) })
        .base_uri("https://api.tally.so")
        .headers(
          "Authorization" => "Bearer #{api_key}",
          "tally-version" => "2025-02-01",
          "Content-Type" => "application/json",
        ),
      HTTP::Session,
    )
  end

  # == Methods ==

  sig do
    params(
      form_id: String,
      after_id: T.nilable(String),
      page: T.nilable(Integer),
      limit: T.nilable(Integer),
    ).returns(ListSubmissionsResponse)
  end
  def list_form_submissions(form_id:, after_id: nil, page: nil, limit: nil)
    params = {
      afterId: after_id,
      page:,
      limit:,
    }.compact
    response = get!("/forms/#{form_id}/submissions", params:)
    questions = response.fetch("questions").map do |q|
      Question.new(
        key: q.fetch("key"),
        label: q.fetch("label"),
        type: q.fetch("type"),
      )
    end
    submissions = response.fetch("submissions").map do |s|
      fields = s.fetch("fields").map do |f|
        Field.new(
          key: f.fetch("key"),
          label: f.fetch("label"),
          type: f.fetch("type"),
          value: f["value"],
        )
      end
      Submission.new(
        submission_id: s.fetch("submissionId"),
        response_id: s.fetch("responseId"),
        respondent_id: s.fetch("respondentId"),
        form_id: s.fetch("formId"),
        created_at: Time.zone.parse(s.fetch("createdAt")),
        fields:,
      )
    end
    ListSubmissionsResponse.new(
      page: response.fetch("page"),
      limit: response.fetch("limit"),
      has_more: response.fetch("hasMore"),
      questions:,
      submissions:,
    )
  end

  private

  # == Helpers ==

  sig { params(path: String, options: T.untyped).returns(T.untyped) }
  def get!(path, **options)
    response = @session.get(path, **options)
    check_response!(response)
    response.parse
  end

  sig { params(response: HTTP::Response).void }
  def check_response!(response)
    unless response.status.success?
      case response.code
      when 429
        raise TooManyRequests, response
      else
        raise BadResponse, response
      end
    end
  end
end
```

- [ ] **Step 2: Verify it loads**

Run: `mise x -- bin/rails runner "Tally"`

Expected: no error (class loads successfully via autoload).

- [ ] **Step 3: Commit**

```bash
git add lib/tally.rb
git commit -m "Add Tally HTTP client

Thin wrapper around the Tally API using http.rb. Supports listing form
submissions with cursor-based pagination (afterId). Follows the same
patterns as lib/luma.rb."
```

---

### Task 2: Create the Notion HTTP client

**Files:**

- Create: `lib/notion.rb`

**Reference:** `docs/research/notion_api.md` — data source query, page creation,
property types. **Pattern to follow:** `lib/luma.rb` — same structure. Key
difference: Notion needs both `get!` and `post!` helpers, and the initializer
param is `integration_secret:` (not `api_key:`).

- [ ] **Step 1: Create `lib/notion.rb`**

```ruby
# typed: true
# frozen_string_literal: true

require "rails"
require "http"

class Notion
  extend T::Sig

  # == Models ==

  class Page < T::Struct
    const :id, String
    const :url, String
    const :created_time, ActiveSupport::TimeWithZone
    const :properties, T::Hash[String, T.untyped]
  end

  class QueryDataSourceResponse < T::Struct
    const :results, T::Array[Page]
    const :has_more, T::Boolean
    const :next_cursor, T.nilable(String)
  end

  # == Exceptions ==

  class Error < StandardError; end

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

  class TooManyRequests < BadResponse; end

  # == Configuration ==

  sig { params(integration_secret: String).void }
  def initialize(integration_secret:)
    @session = T.let(
      HTTP
        .use(logging: { logger: Rails.logger.tagged(self.class.name) })
        .base_uri("https://api.notion.com")
        .headers(
          "Authorization" => "Bearer #{integration_secret}",
          "Notion-Version" => "2026-03-11",
          "Content-Type" => "application/json",
        ),
      HTTP::Session,
    )
  end

  # == Methods ==

  sig do
    params(
      data_source_id: String,
      filter: T.nilable(T::Hash[String, T.untyped]),
      sorts: T.nilable(T::Array[T::Hash[String, T.untyped]]),
      start_cursor: T.nilable(String),
      page_size: T.nilable(Integer),
    ).returns(QueryDataSourceResponse)
  end
  def query_data_source(data_source_id:, filter: nil, sorts: nil, start_cursor: nil, page_size: nil)
    body = {
      filter:,
      sorts:,
      start_cursor:,
      page_size:,
    }.compact
    response = post!("/v1/data_sources/#{data_source_id}/query", json: body)
    results = response.fetch("results").map do |page|
      Page.new(
        id: page.fetch("id"),
        url: page.fetch("url"),
        created_time: Time.zone.parse(page.fetch("created_time")),
        properties: page.fetch("properties"),
      )
    end
    QueryDataSourceResponse.new(
      results:,
      has_more: response.fetch("has_more"),
      next_cursor: response["next_cursor"],
    )
  end

  sig do
    params(
      parent: T::Hash[String, T.untyped],
      properties: T::Hash[String, T.untyped],
    ).returns(Page)
  end
  def create_page(parent:, properties:)
    response = post!("/v1/pages", json: { parent:, properties: })
    Page.new(
      id: response.fetch("id"),
      url: response.fetch("url"),
      created_time: Time.zone.parse(response.fetch("created_time")),
      properties: response.fetch("properties"),
    )
  end

  private

  # == Helpers ==

  sig { params(path: String, options: T.untyped).returns(T.untyped) }
  def post!(path, **options)
    response = @session.post(path, **options)
    check_response!(response)
    response.parse
  end

  sig { params(response: HTTP::Response).void }
  def check_response!(response)
    unless response.status.success?
      case response.code
      when 429
        raise TooManyRequests, response
      else
        raise BadResponse, response
      end
    end
  end
end
```

- [ ] **Step 2: Verify it loads**

Run: `mise x -- bin/rails runner "Notion"`

Expected: no error (class loads successfully via autoload).

- [ ] **Step 3: Commit**

```bash
git add lib/notion.rb
git commit -m "Add Notion HTTP client

Thin wrapper around the Notion API using http.rb. Supports querying a
data source and creating pages. Follows the same patterns as lib/luma.rb."
```

---

### Task 3: Add Tally and Notion singletons to `config/application.rb`

**Files:**

- Modify: `config/application.rb:80-119` (the singletons and class accessors
  section)

**Pattern to follow:** The existing `#wa_sender_api` and `#luma` singleton
methods (lines 82-98) and the class-level accessors (lines 115-119).

- [ ] **Step 1: Add `#tally` and `#notion` singleton methods inside
      `HappyTown::Application`**

Add these two methods after the `#luma` method (after line 98, before the
commented-out `#open_router`):

```ruby
    sig { returns(Tally) }
    def tally
      return @tally if defined?(@tally)

      api_key = credentials.tally.api_key or
        raise "Missing Tally API key"
      @tally = Tally.new(api_key:)
    end

    sig { returns(Notion) }
    def notion
      return @notion if defined?(@notion)

      integration_secret = credentials.notion.integration_secret or
        raise "Missing Notion integration secret"
      @notion = Notion.new(integration_secret:)
    end
```

- [ ] **Step 2: Add class-level accessors on the `HappyTown` module**

Add these after the existing `def self.wa_sender_api` (after line 119, before
the closing `end`):

```ruby
  sig { returns(Tally) }
  def self.tally = application.tally

  sig { returns(Notion) }
  def self.notion = application.notion
```

- [ ] **Step 3: Verify singletons load**

Run: `mise x -- bin/rails runner "HappyTown.tally; HappyTown.notion"`

Expected: will raise `"Missing Tally API key"` or
`"Missing Notion integration secret"` if credentials aren't set yet. That's fine
— it confirms the singleton wiring works. If credentials are set, it will
succeed silently.

- [ ] **Step 4: Commit**

```bash
git add config/application.rb
git commit -m "Add Tally and Notion singletons to HappyTown::Application

Follows the existing pattern used by #luma and #wa_sender_api.
Credentials: tally.api_key, notion.integration_secret."
```

---

### Task 4: Create `app/models/springaling.rb` with the stub property-mapping method

**Files:**

- Create: `app/models/springaling.rb`

**Context:** This file previously existed but was lost during a git
stash/restore cycle. Recreate it from scratch. It's a module (not a class) that
holds config accessors reading from `Rails.configuration.x.springaling`, plus
the stubbed `notion_page_properties_from_tally_submission` method.

- [ ] **Step 1: Create `app/models/springaling.rb`**

```ruby
# typed: true
# frozen_string_literal: true

module Springaling
  extend T::Sig

  sig { returns(String) }
  def self.tally_form_id = configuration.tally_form_id!

  sig { returns(String) }
  def self.notion_data_source_id = configuration.notion_data_source_id!

  sig { params(submission: Tally::Submission).returns(T::Hash[String, T.untyped]) }
  def self.notion_page_properties_from_tally_submission(submission)
    raise NotImplementedError,
      "Springaling.notion_page_properties_from_tally_submission is not yet " \
      "implemented. Define the mapping from Tally::Submission fields to " \
      "Notion page properties."
  end

  private

  sig { returns(T.untyped) }
  private_class_method def self.configuration
    Rails.configuration.x.springaling
  end
end
```

- [ ] **Step 2: Verify it loads**

Run: `mise x -- bin/rails runner "Springaling.tally_form_id"`

Expected: `"LZY1JG"` (reads from `config.x.springaling.tally_form_id` in
`config/application.rb`).

- [ ] **Step 3: Commit**

```bash
git add app/models/springaling.rb
git commit -m "Add Springaling config module with stubbed property mapper

Provides Springaling.tally_form_id and .notion_data_source_id from
config.x, plus notion_page_properties_from_tally_submission which
raises NotImplementedError until the Notion schema is finalized."
```

---

### Task 5: Implement the import job

**Files:**

- Modify: `app/jobs/springaling/import_tally_submissions_job.rb`

**Context:** This file already exists as an empty stub:

```ruby
class Springaling::ImportTallySubmissionsJob < ApplicationJob
  sig { void }
  def perform
  end
end
```

Fill in `#perform` and add the two private helpers.

- [ ] **Step 1: Replace the job file contents**

```ruby
# typed: true
# frozen_string_literal: true

class Springaling::ImportTallySubmissionsJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: :global, on_conflict: :discard

  # == Job ==

  sig { void }
  def perform
    after_id = last_imported_submission_id
    submissions = fetch_new_tally_submissions(after_id:)
    submissions.each do |submission|
      HappyTown.notion.create_page(
        parent: {
          type: "data_source_id",
          data_source_id: Springaling.notion_data_source_id,
        },
        properties: Springaling.notion_page_properties_from_tally_submission(submission),
      )
    end
    logger.info("Imported #{submissions.size} Tally submissions")
  end

  private

  # == Helpers ==

  sig { returns(T.nilable(String)) }
  def last_imported_submission_id
    response = HappyTown.notion.query_data_source(
      data_source_id: Springaling.notion_data_source_id,
      filter: {
        property: "tally submission ID",
        rich_text: { is_not_empty: true },
      },
      sorts: [{ property: "submitted at", direction: "descending" }],
      page_size: 1,
    )
    page = response.results.first or return nil
    rich_text = page.properties.dig("tally submission ID", "rich_text") || []
    rich_text.map { |t| t.fetch("plain_text") }.join.presence
  end

  sig { params(after_id: T.nilable(String)).returns(T::Array[Tally::Submission]) }
  def fetch_new_tally_submissions(after_id:)
    all = T.let([], T::Array[Tally::Submission])
    page_num = 1
    loop do
      response = HappyTown.tally.list_form_submissions(
        form_id: Springaling.tally_form_id,
        after_id:,
        page: page_num,
      )
      all.concat(response.submissions)
      break unless response.has_more
      page_num += 1
    end
    all.reverse
  end
end
```

- [ ] **Step 2: Verify the job class loads**

Run: `mise x -- bin/rails runner "Springaling::ImportTallySubmissionsJob"`

Expected: no error.

- [ ] **Step 3: Commit**

```bash
git add app/jobs/springaling/import_tally_submissions_job.rb
git commit -m "Implement Springaling Tally-to-Notion import job

Queries Notion for the most recent tally submission ID, fetches new
submissions from Tally after that cursor, and creates Notion pages
for each. Processes oldest-first for fail-fast resumability."
```

---

### Task 6: Run Sorbet type checking

**Files:** None (verification only)

- [ ] **Step 1: Run Sorbet**

Run: `mise x -- bundle exec srb tc`

Expected: no new type errors from the files we created/modified. If there are
errors, fix them before proceeding.

- [ ] **Step 2: Run Rubocop**

Run:
`mise x -- bundle exec rubocop lib/tally.rb lib/notion.rb app/models/springaling.rb app/jobs/springaling/import_tally_submissions_job.rb config/application.rb`

Expected: no offenses. If there are, fix and amend the most recent relevant
commit.
