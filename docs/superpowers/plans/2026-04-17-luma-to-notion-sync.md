# Luma-to-Notion Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically sync LumaEvent records to the Notion "🎟️ events" data source on every save.

**Architecture:** `LumaEvent#sync_to_notion` does the upsert (find-by-luma-id then update-or-create). `sync_to_notion_later` enqueues it as a background job. An `after_save` callback wires it all together.

**Tech Stack:** Rails, Sorbet, `Notion::Client` (lib/notion/client.rb), SolidQueue (job queue).

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `config/application.rb` | Modify | Add `config.x.luma_events.notion_data_source_id` |
| `app/models/luma_event.rb` | Modify | Add `sync_to_notion`, `sync_to_notion_later`, `notion_page_properties`, `after_save` callback |
| `app/jobs/sync_luma_event_to_notion_job.rb` | Create | Async wrapper job |

---

## Task 1: Add config

**Files:**
- Modify: `config/application.rb`

- [ ] **Step 1: Add the Luma Events config block**

In `config/application.rb`, after the `# == Spring-a-ling` block (around line 57), add:

```ruby
# == Luma Events ==
config.x.luma_events.notion_data_source_id =
  "317d2193-c198-8090-be97-000bbe41afed"
```

- [ ] **Step 2: Verify it loads**

```bash
mise x -- bin/rails runner "puts Rails.configuration.x.luma_events.notion_data_source_id"
```

Expected output: `317d2193-c198-8090-be97-000bbe41afed`

---

## Task 2: Create the job

**Files:**
- Create: `app/jobs/sync_luma_event_to_notion_job.rb`

- [ ] **Step 1: Write the job file**

```ruby
# typed: true
# frozen_string_literal: true

class SyncLumaEventToNotionJob < ApplicationJob
  # == Configuration ==

  queue_as :default
  limits_concurrency key: ->(event) { event }, on_conflict: :discard

  # == Job ==

  sig { params(event: LumaEvent).void }
  def perform(event)
    tag_logger do
      logger.info("Syncing Luma event to Notion: #{event.luma_id}")
    end
    event.sync_to_notion
  end
end
```

---

## Task 3: Add Notion sync to `LumaEvent`

**Files:**
- Modify: `app/models/luma_event.rb`

Property mapping:

| LumaEvent | Notion property | Type |
|-----------|-----------------|------|
| `luma_id` | `luma id` | rich_text |
| `name` | `name` | title |
| `start_at` / `end_at` | `date` | date range (datetime) |
| `tags.map(&:name)` | `tags` | multi_select |
| `url` | `luma link` | url |

`luma_event.tags` returns `LumaEventTag` records (from `LumaEventTag.where(luma_id: tag_ids)`). Each has a `.name` string attribute.

- [ ] **Step 1: Add `after_save` callback in the `# == Configuration ==` section**

```ruby
after_save :sync_to_notion_later
```

- [ ] **Step 2: Add public `# == Notion ==` section (before `private`)**

```ruby
# == Notion ==

sig { returns(Notion::Page) }
def sync_to_notion
  data_source_id = Rails.configuration.x.luma_events.notion_data_source_id
  response = HappyTown.notion.query_data_source(
    data_source_id:,
    filter: { property: "luma id", rich_text: { equals: luma_id } },
    page_size: 1,
  )
  if (page = response.results.first)
    HappyTown.notion.update_page(
      page_id: page.id,
      properties: notion_page_properties,
    )
  else
    HappyTown.notion.create_page(
      parent: { type: "data_source_id", data_source_id: },
      properties: notion_page_properties,
    )
  end
end

sig { void }
def sync_to_notion_later
  SyncLumaEventToNotionJob.perform_later(self)
end
```

- [ ] **Step 3: Add private `notion_page_properties` helper (inside `private`)**

```ruby
sig { returns(T::Hash[String, T.untyped]) }
def notion_page_properties
  {
    "name" => {
      "title" => [ { "text" => { "content" => name } } ],
    },
    "luma id" => {
      "rich_text" => [ { "type" => "text", "text" => { "content" => luma_id } } ],
    },
    "luma link" => {
      "url" => url,
    },
    "date" => {
      "date" => { "start" => start_at.iso8601, "end" => end_at.iso8601 },
    },
    "tags" => {
      "multi_select" => tags.map { |t| { "name" => t.name } },
    },
  }
end
```

---

## Task 4: Regenerate Tapioca DSL RBIs and commit

**Files:**
- Auto-generated: `sorbet/rbi/dsl/luma_event.rbi`
- Auto-generated: `sorbet/rbi/dsl/sync_luma_event_to_notion_job.rbi`

- [ ] **Step 1: Regenerate DSL RBIs**

```bash
mise x -- bin/tapioca dsl LumaEvent SyncLumaEventToNotionJob
```

- [ ] **Step 2: Verify no Sorbet errors**

```bash
mise x -- bin/srb tc
```

Expected: no errors

- [ ] **Step 3: Commit everything**

```bash
git add \
  config/application.rb \
  app/models/luma_event.rb \
  app/jobs/sync_luma_event_to_notion_job.rb \
  docs/superpowers/specs/2026-04-17-luma-to-notion-sync-design.md \
  docs/superpowers/plans/2026-04-17-luma-to-notion-sync.md \
  sorbet/rbi/dsl/luma_event.rbi \
  sorbet/rbi/dsl/sync_luma_event_to_notion_job.rbi

git commit -m "Sync LumaEvent to Notion on save

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
