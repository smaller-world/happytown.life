# Luma-to-Notion Event Sync

## Overview

Sync `LumaEvent` records to Notion automatically whenever they are saved. The sync finds an existing Notion page by `luma id` property, updates it if found, or creates a new page if not.

## Data Source

Notion data source ID: `317d2193-c198-8090-be97-000bbe41afed` (🎟️ events)

## Property Mapping

| LumaEvent attribute         | Notion property | Type         |
| --------------------------- | --------------- | ------------ |
| `luma_id`                   | `luma id`       | text         |
| `name`                      | `name`          | title        |
| `start_at` / `end_at`       | `date`          | date range   |
| `tags.map(&:name)`          | `tags`          | multi_select |
| `url`                       | `luma link`     | url          |

Tags are resolved from `LumaEvent#tags` which returns `LumaEventTag` models with a `.name` attribute. The name string is passed directly to Notion's multi_select format.

Dates are synced as datetime ranges (both start and end, using ISO-8601 datetime format).

## Architecture

### `LumaEvent#sync_to_notion`

Instance method on `LumaEvent`. Responsible for:

1. Querying the Notion data source filtered by `luma id = self.luma_id`
2. If a page exists: call `Notion::Client#update_page`
3. If no page exists: call `Notion::Client#create_page`
4. Returns the resulting `Notion::Page`

Raises immediately on any Notion API error (e.g. `Notion::BadResponse`, `Notion::TooManyRequests`). No internal retry logic.

### `LumaEvent#sync_to_notion_later`

Enqueues `SyncLumaEventToNotionJob` for async execution.

### `LumaEvent` after_save callback

```ruby
after_save :sync_to_notion_later
```

Triggers a background sync every time a LumaEvent is created or updated.

### `SyncLumaEventToNotionJob`

New job in `app/jobs/sync_luma_event_to_notion_job.rb`:

- Receives a `LumaEvent` record
- Calls `luma_event.sync_to_notion`
- Relies on Solid Queue's built-in retry mechanism for transient failures
- Queue: `:default`

## Notion Property Format

```ruby
{
  "name"      => { "title" => [{ "text" => { "content" => name } }] },
  "luma id"   => { "rich_text" => [{ "type" => "text", "text" => { "content" => luma_id } }] },
  "luma link" => { "url" => url },
  "date"      => { "date" => { "start" => start_at.iso8601, "end" => end_at.iso8601 } },
  "tags"      => { "multi_select" => tags.map { |t| { "name" => t.name } } },
}
```

## Error Handling

- `sync_to_notion` raises on all errors — callers must handle or let it propagate
- `SyncLumaEventToNotionJob` retries via Solid Queue's default retry policy
- `Notion::TooManyRequests` (429) will be retried like any other error

## Files to Create / Modify

| File                                              | Change          |
| ------------------------------------------------- | --------------- |
| `app/models/luma_event.rb`                        | Add `sync_to_notion`, `sync_to_notion_later`, `after_save` callback, `notion_page_properties` private helper |
| `app/jobs/sync_luma_event_to_notion_job.rb`       | Create new job  |

## Out of Scope

- Syncing `description`, `geo_location`, `geo_address`, `time_zone_name` (no matching Notion properties)
- Deleting Notion pages when a LumaEvent is destroyed
- Two-way sync (Notion → Luma)
- Rate-limit-aware batching
