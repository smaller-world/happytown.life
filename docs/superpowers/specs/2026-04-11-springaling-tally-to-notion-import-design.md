# Springaling: Tally → Notion submission import

**Date:** 2026-04-11 **Status:** Design approved, ready for implementation plan

## Summary

Add a background job that imports new Tally form submissions into a Notion data
source. The job discovers which submissions are new by querying Notion itself
for the most recent previously-imported submission ID, then fetches submissions
from Tally `afterId` that cursor and creates one Notion page per submission.

Introduces two new HTTP client libraries (`lib/tally.rb`, `lib/notion.rb`)
scoped tightly to what this feature needs, and fills in the existing empty job
at `app/jobs/springaling/import_tally_submissions_job.rb`.

## Goals

- One-way sync from Tally form submissions to Notion data source pages.
- Idempotent: re-running the job never creates duplicate Notion pages.
- Resumable: a crashed/failed run leaves a clean state; the next run picks up
  exactly where the previous one left off.
- Empty-Notion first-run imports the full Tally form history.

## Non-goals

- Two-way sync or updates. Only _new_ Tally submissions become Notion pages;
  edits in either system don't propagate.
- Deletion propagation.
- Automatic scheduling. The job is triggered manually
  (`Springaling::ImportTallySubmissionsJob.perform_later`) for now; recurring
  execution is a future concern.
- Implementing `Springaling.notion_page_properties_from_tally_submission` — it
  is deliberately stubbed as `NotImplementedError` and will be filled in later
  once the target Notion schema is finalized.
- Testing. No unit or integration tests are part of this spec (matches the bar
  set by existing `lib/luma.rb` and `lib/wa_sender_api.rb`).

## File changes

### New files

1. **`lib/tally.rb`** — `class Tally` HTTP client for the Tally API.
2. **`lib/notion.rb`** — `class Notion` HTTP client for the Notion API.

### Modified files

3. **`config/application.rb`**
   - Add `HappyTown::Application#tally` and `#notion` singletons following the
     existing `#luma` / `#wa_sender_api` pattern.
   - Add class-level `HappyTown.tally` and `HappyTown.notion` accessors.
   - `config.x.springaling.tally_form_id` and
     `config.x.springaling.notion_data_source_id` stay hardcoded (already
     present). The placeholder `"..."` in `notion_data_source_id` must be
     replaced with the real ID before the job will run successfully.

4. **`app/models/springaling.rb`**
   - Add a new module method
     `Springaling.notion_page_properties_from_tally_submission(submission)` that
     raises `NotImplementedError`. Its signature takes a `Tally::Submission` and
     returns `T::Hash[String, T.untyped]` (Notion property values keyed by
     property name).

5. **`app/jobs/springaling/import_tally_submissions_job.rb`**
   - Fill in the `#perform` body. Add `queue_as :default` and
     `limits_concurrency key: :global, on_conflict: :discard` (same settings as
     `ImportLumaEventsJob`).

## Client design

Both clients match the shape of `lib/luma.rb`:

- `extend T::Sig`, `# typed: true`, `# frozen_string_literal: true`.
- `HTTP.use(logging: { logger: Rails.logger.tagged(self.class.name) })` for
  request logging.
- Exception hierarchy: `Error` / `BadResponse` / `TooManyRequests` nested under
  the class, with `BadResponse` wrapping the `HTTP::Response`.
- Private `get!` / `post!` / `check_response!` helpers.
- `T::Struct` types for response payloads, narrow to only the fields the feature
  actually reads.

### `lib/tally.rb`

**Configuration:**

- `initialize(api_key:)`
- Base URI `https://api.tally.so`
- Headers:
  - `Authorization: Bearer <api_key>`
  - `tally-version: 2025-02-01`
  - `Content-Type: application/json`

**Types:**

```ruby
class Question < T::Struct
  const :key, String
  const :label, String
  const :type, String
end

class Field < T::Struct
  const :key, String
  const :label, String
  const :type, String
  const :value, T.untyped # varies by field type
end

class Submission < T::Struct
  const :submission_id, String            # from "submissionId"
  const :response_id, String
  const :respondent_id, String
  const :form_id, String
  const :created_at, ActiveSupport::TimeWithZone # parsed from "createdAt"
  const :fields, T::Array[Field]
end

class ListSubmissionsResponse < T::Struct
  const :page, Integer
  const :limit, Integer
  const :has_more, T::Boolean
  const :questions, T::Array[Question]
  const :submissions, T::Array[Submission]
end
```

**Methods:**

```ruby
sig do
  params(
    form_id: String,
    after_id: T.nilable(String),
    page: T.nilable(Integer),
    limit: T.nilable(Integer),
  ).returns(ListSubmissionsResponse)
end
def list_form_submissions(form_id:, after_id: nil, page: nil, limit: nil)
  # GET /forms/{form_id}/submissions
  # Query params: { afterId:, page:, limit: }.compact
end
```

### `lib/notion.rb`

**Configuration:**

- `initialize(integration_secret:)`
- Base URI `https://api.notion.com`
- Headers:
  - `Authorization: Bearer <integration_secret>`
  - `Notion-Version: 2026-03-11`
  - `Content-Type: application/json`

**Types:**

```ruby
class Page < T::Struct
  const :id, String
  const :url, String
  const :created_time, ActiveSupport::TimeWithZone
  const :properties, T::Hash[String, T.untyped] # raw Notion property values
end

class QueryDataSourceResponse < T::Struct
  const :results, T::Array[Page]
  const :has_more, T::Boolean
  const :next_cursor, T.nilable(String)
end
```

`Page#properties` stays as a raw `Hash` on purpose: each data source has a
different schema, and modeling Notion's full property-value zoo in Sorbet
structs would be high effort for low payoff. Call sites read the handful of
properties they care about with `page.properties.dig(...)`.

**Methods:**

```ruby
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
  # POST /v1/data_sources/{data_source_id}/query
  # Body: { filter:, sorts:, start_cursor:, page_size: }.compact
end

sig do
  params(
    parent: T::Hash[String, T.untyped],
    properties: T::Hash[String, T.untyped],
  ).returns(Page)
end
def create_page(parent:, properties:)
  # POST /v1/pages
  # Body: { parent:, properties: }
end
```

## Application singletons

`config/application.rb` adds two new singleton accessors, following the exact
shape of `#luma` / `#wa_sender_api`:

```ruby
sig { returns(Tally) }
def tally
  return @tally if defined?(@tally)
  api_key = credentials.tally.api_key or raise "Missing Tally API key"
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

And at the `HappyTown` module level:

```ruby
sig { returns(Tally) }
def self.tally = application.tally

sig { returns(Notion) }
def self.notion = application.notion
```

Credentials required (both in `credentials.yml.enc`):

- `tally.api_key`
- `notion.integration_secret`

## Import algorithm

Implemented in `Springaling::ImportTallySubmissionsJob#perform`:

```ruby
class Springaling::ImportTallySubmissionsJob < ApplicationJob
  queue_as :default
  limits_concurrency key: :global, on_conflict: :discard

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
    all = []
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
    all.reverse # oldest → newest; see "Ordering" below
  end
end
```

### Step-by-step

1. **Find the cursor.** Query the Notion data source for the one most recent
   page that already has a `tally submission ID` set. Extract the plain-text
   value of that rich_text property and use it as `after_id` for Tally. If there
   is no such page, `after_id` is `nil` → Tally returns the full form history.

2. **Fetch all new submissions.** Loop over Tally pages until `has_more` is
   `false`, accumulating every submission into one array.

3. **Reverse in memory.** This step assumes Tally returns submissions
   newest-first both within a page and across pages (i.e., page 1 contains the
   newest submissions, page 2 the next-newest, and so on). Under that
   assumption, reversing the full concatenated array yields strict oldest →
   newest order, which is required for a clean fail-fast resumable state. If
   Tally's actual ordering turns out to differ during implementation, the sort
   strategy here must be adjusted accordingly — the rest of the algorithm does
   not care _how_ we get to oldest → newest, only that we do. Memory is not a
   concern at this form's volume.

4. **Create pages sequentially.** For each submission, call
   `Springaling.page_properties_from_tally_submission(submission)` (currently
   `NotImplementedError`) and pass the result to `Notion#create_page`.

5. **Any exception aborts the run.** See "Error handling" below.

### Notion schema assumptions

The Notion data source is expected to have:

- A **`tally submission ID`** property of type **`rich_text`**. Required to be
  set on every page created by this job (the
  `page_properties_from_tally_submission` helper is responsible for populating
  it).
- A **`submitted at`** property of type **`date`**. Also populated by the
  helper.

If these property names or types change, the query filter/sort in
`last_imported_submission_id` must be updated in lockstep.

## Error handling

Fail-fast, end to end:

- Any exception raised by `Tally`, `Notion`, or
  `page_properties_from_tally_submission` propagates out of `#perform`.
- `ApplicationJob` has `rescue_from Exception, with: :report_to_sentry` which
  captures the error to Sentry and re-raises it. The job fails in SolidQueue and
  can be manually re-run after the underlying issue is fixed.
- Because submissions are processed oldest → newest and the "cursor" is derived
  from what actually exists in Notion, a partially-completed run leaves a
  perfectly clean resumable state: the next run will start from the last
  successfully-imported submission ID, so nothing is skipped and nothing is
  duplicated.
- `limits_concurrency key: :global, on_conflict: :discard` ensures two runs
  can't interleave.

## Observability

- Rails automatically tags job log lines with the job class name, so no manual
  `tag_logger` wrapper is needed in `#perform`.
- HTTP clients log every request via
  `HTTP.use(logging: { logger: Rails.logger.tagged(self.class.name) })`,
  matching `Luma` and `WaSenderApi`.
- A single summary line at the end of a successful run:
  `logger.info("Imported #{n} Tally submissions")`.
- Failures land in Sentry via `ApplicationJob#report_to_sentry`.

## Known follow-ups / open items

- `notion_data_source_id` is still the literal placeholder `"..."` in
  `config/application.rb:60`. This must be replaced with the real Notion data
  source ID before the job can run successfully in any environment.
- `Springaling.notion_page_properties_from_tally_submission` raises
  `NotImplementedError`. A follow-up change will implement it once the target
  Notion property schema is finalized.
- The job has no recurring schedule yet. Wiring it into SolidQueue's recurring
  config (or equivalent) is out of scope.
