# Implement `Springaling.notion_page_properties_from_tally_submission`

**Date:** 2026-04-12

## Context

The `lib/springaling.rb` module has a stubbed `notion_page_properties_from_tally_submission` method that raises `NotImplementedError`. This method needs to map a `Tally::Submission` (from the Tally host form) to a Notion `properties` hash suitable for `Notion#create_page`.

## Tally Submission Structure

From `tmp/tally_submissions.json`, each submission has:

```json
{
  "id": "2jXZpPg",
  "respondent_id": "RGBBEN4",
  "form_id": "LZY1JG",
  "submitted_at": "2026-04-12 00:15:06 UTC",
  "responses": [
    { "id": "xRVqXDJ", "question_id": "Woz25a", "answer": "Cami" },
    { "id": "Z197jOa", "question_id": "axd9Yq", "answer": "sayheyhouse@gmail.com" },
    { "id": "NbqjpXW", "question_id": "6kNL2B", "answer": "Design your own tarot card" },
    { "id": "2ljWEAA", "question_id": "7Dxq2A", "answer": ["promotion"] },
    { "id": "qJ5r4Gd", "question_id": "yyYMkx", "answer": "2026-05-12" },
    { "id": "QzoZKRA", "question_id": "XG0LyY", "answer": "2026-05-19" },
    { "id": "9RNkqZ1", "question_id": "0MOd5j", "answer": "18:00" }
  ]
}
```

The `Tally::Submission` model has `fields: T::Array[Tally::Field]` where each `Field` has `key`, `label`, `type`, `value`.

## Notion Data Source Schema

The `✋ host form submissions` data source (`collection://33dd2193-c198-8045-9070-000bd552368a`) has these columns:

| Notion Property | Type |
|---|---|
| `name` | title |
| `contact` | rich_text |
| `event idea` | rich_text |
| `needs support with` | multi_select (options: "promotion", "organizing/hosting") |
| `suggested date` | date |
| `alt date` | date |
| `status` | status (unreviewed, contacted, planned, rejected) |
| `submitted at` | date |
| `tally submission ID` | rich_text |

## Field Mapping

| Tally `question_id` | Meaning | Notion property | Write format |
|---|---|---|---|
| `Woz25a` | Name | `name` | `title: [{ text: { content: value.strip } }]` |
| `axd9Yq` | Email | `contact` | `rich_text: [{ type: "text", text: { content: value } }]` |
| `6kNL2B` | Event idea | `event idea` | `rich_text` (same format) |
| `7Dxq2A` | Needs support with | `needs support with` | `multi_select: [{ name: "promotion" }, ...]` |
| `yyYMkx` + `0MOd5j` | Suggested date + time | `suggested date` | `date: { start: "2026-05-12T18:00:00", time_zone: "America/Toronto" }` |
| `XG0LyY` + `0MOd5j` | Alt date + time | `alt date` | Same format — **omitted** if same date as suggested |
| `submission_id` | Submission ID | `tally submission ID` | `rich_text` |
| `submission.created_at` | Created timestamp | `submitted at` | `date` with `time_zone: "America/Toronto"`, `is_datetime: true` |

## Key Rules

1. **Lookup by `key`** (the question_id), not label. Build a `key → value` hash from `submission.fields`.
2. **Time merging** — combine date (`"2026-05-12"`) + time (`"18:00"`) → `"2026-05-12T18:00:00"` with `time_zone: "America/Toronto"`
3. **Alt date dedup** — if alt date string equals suggested date string, **omit** the `alt date` property entirely from the returned hash
4. **Missing fields** — write empty string / null, do NOT raise. The import continues.
5. **`submitted at`** — uses `submission.created_at.in_time_zone("America/Toronto").iso8601` with `is_datetime: true`
6. **Timezone** — always `"America/Toronto"` for all date fields

## Notion API Property Value Formats

For reference (from Notion API docs):

- **title**: `{ "title": [{ "text": { "content": "value" } }] }`
- **rich_text**: `{ "rich_text": [{ "type": "text", "text": { "content": "value" } }] }`
- **date**: `{ "date": { "start": "2026-05-12T18:00:00", "end": null, "time_zone": "America/Toronto" } }`
- **multi_select**: `{ "multi_select": [{ "name": "promotion" }, { "name": "organizing/hosting" }] }`

## Implementation

**File:** `lib/springaling.rb`

1. Add question ID constants at module level
2. Add `TIMEZONE = "America/Toronto"` constant
3. Replace the `NotImplementedError` stub with the full mapping
4. Add private `notion_date_value(date, time, is_datetime:)` helper that:
   - If both date and time present → `"{date}T{time}:00"` with `time_zone: TIMEZONE`
   - If only date present → just the date string, no timezone
   - If neither → `nil`
5. Alt date is conditionally added via `.tap` — only if `alt_date.present? && alt_date != suggested_date`

### Sorbet considerations

- The `Tally::Submission`, `Tally::Field` types are `T::Struct` — Sorbet may need RBI regeneration via `bin/tapioca dsl Tally` and/or `bin/tapioca annotations`
- The return type is `T::Hash[String, T.untyped]` to accommodate the varied Notion property structures
- May need `T.unsafe` or `T.let` for the `submission.fields` access if RBI isn't available

## Verification

After implementation, run:
- `bin/tapioca dsl Tally` to regenerate DSL RBI
- `srb tc` to verify type checking passes
- Optionally test manually with data from `tmp/tally_submissions.json`
