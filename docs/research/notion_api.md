# Notion API — Creating Database Entries (Pages)

> **Current API version:** `2026-03-11` (latest as of April 2026)
> **Key change since 2025-09-03:** The "data source" object was introduced, separating the concept of a database (container) from data sources (individual tables). Pages are children of data sources.

---

## Data Model Hierarchy

```
Database (container, holds 1+ data sources)
└── Data Source (the actual table)
    └── Page (a row/entry in the table)
        └── Block (content within the page)
```

- **Database**: A container that can hold multiple data sources. Has `is_inline`, `title`, `description`, etc.
- **Data Source**: The individual table of data. Contains the `properties` schema that all child pages must conform to.
- **Page**: A single row/entry in a data source. Property values must match the parent data source's schema.

### Important IDs you need

| What | Where to get it |
|------|----------------|
| **Data source ID** | `GET /v1/data_sources/<database_id>` — returns the data source object with its `id` and `properties` schema |
| **Database ID** | The UUID from the Notion URL, or via search API |
| **Page ID** | Returned from `POST /v1/pages` (create), or from querying a data source |

---

## Authentication

All requests require a Bearer token in the `Authorization` header:

```
Authorization: Bearer <secret_token>
Notion-Version: 2026-03-11
Content-Type: application/json
```

### Capabilities required

The integration must have **Insert Content** capabilities on the target parent data source. Without this, the API returns `403`.

---

## Status Codes & Error Handling

Notion uses standard HTTP status codes to indicate the success or failure of an API request.

### Error Payload Format

Error responses contain a JSON body with more detail about the error:

```json
{
  "object": "error",
  "status": 400,
  "code": "validation_error",
  "message": "body failed validation: body.properties should be defined, instead was undefined.",
  "request_id": "...",
  "additional_data": {}
}
```

- **`object`**: Always `"error"`.
- **`status`**: The HTTP status code.
- **`code`**: A machine-readable error code (e.g., `"validation_error"`).
- **`message`**: A human-readable error message.
- **`request_id`**: A unique identifier for the request, useful for support.
- **`additional_data`**: (Optional) Extra context, such as retry guidance.

### HTTP Status Codes

| Status Code | `"code"` | Description |
| :--- | :--- | :--- |
| **200** | N/A | Success. |
| **400** | `invalid_json` | Request body could not be decoded as JSON. |
| **400** | `invalid_request_url` | The request URL is not valid. |
| **400** | `invalid_request` | This request is not supported. |
| **400** | `validation_error` | Request body does not match the schema. |
| **400** | `missing_version` | Missing required `Notion-Version` header. |
| **401** | `unauthorized` | Bearer token is invalid or expired. |
| **403** | `restricted_resource` | Client doesn't have permission for this operation. |
| **404** | `object_not_found` | Resource doesn't exist or isn't shared with integration. |
| **409** | `conflict_error` | Transaction could not be completed (e.g., data collision). |
| **429** | `rate_limited` | Request limit exceeded. Check `Retry-After` header. |
| **500** | `internal_server_error` | An unexpected error occurred on Notion's end. |
| **502** | `bad_gateway` | Notion encountered an issue with an upstream server. |
| **503** | `service_unavailable` | Notion is unavailable (e.g., request timeout > 60s). |
| **503** | `database_connection_unavailable` | Notion's database is temporarily unavailable. |
| **504** | `gateway_timeout` | Notion timed out while completing the request. |

---

## Creating a Page (Database Entry)

### Endpoint

```
POST https://api.notion.com/v1/pages
```

### Request Body

```json
{
  "parent": {
    "type": "data_source_id",
    "data_source_id": "<data_source_uuid>"
  },
  "properties": {
    "Title": {
      "title": [
        {
          "type": "text",
          "text": {
            "content": "My Entry Title"
          }
        }
      ]
    },
    "Status": {
      "status": {
        "name": "In Progress"
      }
    },
    "Priority": {
      "number": 1
    },
    "Due date": {
      "date": {
        "start": "2026-04-15"
      }
    },
    "Tags": {
      "multi_select": [
        { "name": "urgent" },
        { "name": "backend" }
      ]
    }
  },
  "icon": { "type": "emoji", "emoji": "📌" },
  "content": [
    {
      "object": "block",
      "type": "paragraph",
      "paragraph": {
        "rich_text": [
          {
            "type": "text",
            "text": { "content": "Page content goes here." }
          }
        ]
      }
    }
  ]
}
```

### Parent types

The `parent` object supports four types. For database entries, use `data_source_id`:

| Parent type | Use case |
|-------------|----------|
| `page_id` | Creates a child page under a page. Only `title` property allowed. |
| **`data_source_id`** | **Creates a row in a data source (database table). Properties must match data source schema.** |
| `workspace` | Creates a workspace-level page (only for public integration bots). |

### Properties rules

- **If parent is a page**: only `title` is a valid property.
- **If parent is a data source**: keys in `properties` must match the parent data source's property names exactly.
- **Cannot set via API**: `rollup`, `created_by`, `created_time`, `last_edited_by`, `last_edited_time` — these are Notion-generated and return errors if included.

### Content options (mutually exclusive)

| Approach | Description |
|----------|-------------|
| `content` (array of blocks) | Build page content block-by-block. Max 100 blocks. |
| `children` (array of blocks) | Same as `content` (legacy alias). Max 100 blocks. |
| `markdown` (string) | Notion-flavored markdown. Newlines must be `\n` encoded in JSON. |
| `template` object | Apply a data source template. See [Templates](#templates) below. |

You can only use **one** of `content`/`children`, `markdown`, or `template`.

### cURL Example

```bash
curl -X POST 'https://api.notion.com/v1/pages' \
  -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
  -H 'Notion-Version: 2026-03-11' \
  -H 'Content-Type: application/json' \
  --data '{
    "parent": {
      "type": "data_source_id",
      "data_source_id": "c174b72c-d782-432f-8dc0-b647e1c96df6"
    },
    "properties": {
      "Task": {
        "title": [
          {
            "type": "text",
            "text": { "content": "Fix login bug" }
          }
        ]
      },
      "Status": {
        "status": { "name": "In Progress" }
      },
      "Priority": { "number": 1 },
      "Assignee": {
        "people": [{ "object": "user", "id": "c2f20311-9e54-4d11-8c79-7398424ae41e" }]
      }
    },
    "content": [
      {
        "object": "block",
        "type": "heading_2",
        "heading_2": {
          "rich_text": [{ "type": "text", "text": { "content": "Details" } }]
        }
      },
      {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
          "rich_text": [{ "type": "text", "text": { "content": "Users cannot log in with SSO." } }]
        }
      }
    ]
  }'
```

### Response (200)

```json
{
  "object": "page",
  "id": "be633bf1-dfa0-436d-b259-571129a590e5",
  "created_time": "2026-04-10T12:00:00.000Z",
  "last_edited_time": "2026-04-10T12:00:00.000Z",
  "created_by": { "object": "user", "id": "c2f20311-9e54-4d11-8c79-7398424ae41e" },
  "last_edited_by": { "object": "user", "id": "c2f20311-9e54-4d11-8c79-7398424ae41e" },
  "in_trash": false,
  "is_archived": false,
  "is_locked": false,
  "url": "https://www.notion.so/Fix-login-bug-be633bf1dfa0436db259571129a590e5",
  "public_url": null,
  "parent": {
    "type": "data_source_id",
    "data_source_id": "c174b72c-d782-432f-8dc0-b647e1c96df6"
  },
  "properties": {
    "Task": { "id": "title", "type": "title", "title": [...] },
    "Status": { "id": "Z%3ClH", "type": "status", "status": { "name": "In Progress", ... } },
    ...
  },
  "icon": { "type": "emoji", "emoji": "📌" },
  "cover": null
}
```

---

## Querying a Data Source (Listing Entries)

To list or search for entries (pages) within a specific table, use the query endpoint.

### Endpoint

```
POST https://api.notion.com/v1/data_sources/<data_source_id>/query
```

### Request Body

```json
{
  "filter": {
    "property": "Status",
    "status": {
      "equals": "In Progress"
    }
  },
  "sorts": [
    {
      "property": "Priority",
      "direction": "descending"
    },
    {
      "timestamp": "created_time",
      "direction": "ascending"
    }
  ],
  "start_cursor": "fe2dc131-...",
  "page_size": 100
}
```

### Filtering

Filters limit results based on property values. You can use single filters or compound filters (`and`/`or`).

#### Simple Filter Examples

| Property Type | Filter Condition |
|---------------|------------------|
| **Checkbox** | `{"property": "Done", "checkbox": {"equals": true}}` |
| **Select** | `{"property": "Type", "select": {"equals": "Bug"}}` |
| **Multi-select** | `{"property": "Tags", "multi_select": {"contains": "Urgent"}}` |
| **Status** | `{"property": "Status", "status": {"equals": "Done"}}` |
| **Date** | `{"property": "Due", "date": {"on_or_after": "2026-04-01"}}` |
| **Number** | `{"property": "Cost", "number": {"greater_than": 100}}` |
| **Text** | `{"property": "Name", "rich_text": {"contains": "Draft"}}` |

#### Compound Filters (`and` / `or`)

```json
{
  "filter": {
    "and": [
      { "property": "Status", "status": { "equals": "In Progress" } },
      { "property": "Priority", "number": { "greater_than_or_equal_to": 2 } }
    ]
  }
}
```

### Sorting

Sorts determine the order of the results. Earlier sorts in the array take precedence.

- **Property Sort**: `{ "property": "Property Name", "direction": "ascending" | "descending" }`
- **Timestamp Sort**: `{ "timestamp": "created_time" | "last_edited_time", "direction": "ascending" | "descending" }`

### Pagination

The API returns a maximum of **100 results** per request.

- **`start_cursor`**: (Optional) Use the `next_cursor` from a previous response to fetch the next page.
- **`page_size`**: (Optional) Number of results per page (default 100, max 100).

The response includes:
- `results`: Array of page objects.
- `has_more`: `true` if there are more results.
- `next_cursor`: Use this for the next request's `start_cursor`.

### cURL Example

```bash
curl -X POST 'https://api.notion.com/v1/data_sources/c174b72c-d782-432f-8dc0-b647e1c96df6/query' \
  -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
  -H 'Notion-Version: 2026-03-11' \
  -H 'Content-Type: application/json' \
  --data '{
    "filter": {
      "property": "Priority",
      "number": { "greater_than_or_equal_to": 1 }
    },
    "sorts": [{ "property": "Due date", "direction": "ascending" }],
    "page_size": 50
  }'
```

---

## Property Types Reference

When creating a page, each property value must match the type defined in the parent data source's schema.

### Title (required for every data source)

```json
{
  "Task": {
    "title": [
      { "type": "text", "text": { "content": "My Task" } }
    ]
  }
}
```

### Rich Text

```json
{
  "Description": {
    "rich_text": [
      {
        "type": "text",
        "text": { "content": "Some description with ", "link": null },
        "annotations": { "bold": false, "italic": false, "strikethrough": false, "underline": false, "code": false, "color": "default" },
        "plain_text": "Some description with ",
        "href": null
      },
      {
        "type": "text",
        "text": { "content": "formatted text", "link": null },
        "annotations": { "bold": true, "italic": false, "strikethrough": false, "underline": false, "code": false, "color": "default" },
        "plain_text": "formatted text",
        "href": null
      }
    ]
  }
}
```

### Number

```json
{ "Priority": { "number": 42 } }
```

### Checkbox

```json
{ "Task completed": { "checkbox": true } }
```

### Select

```json
{
  "Priority": {
    "select": { "name": "High" }
  }
}
```

### Multi-Select

```json
{
  "Tags": {
    "multi_select": [
      { "name": "urgent" },
      { "name": "backend" }
    ]
  }
}
```

New options not yet in the schema will be **auto-created** if the integration has write access to the parent data source.

### Status

```json
{
  "Status": {
    "status": { "name": "In Progress" }
  }
}
```

### Date

```json
{
  "Due date": {
    "date": {
      "start": "2026-04-15",
      "end": null,
      "time_zone": null
    }
  }
}
```

For date ranges, set both `start` and `end`.

### People

```json
{
  "Assignee": {
    "people": [
      { "object": "user", "id": "c2f20311-9e54-4d11-8c79-7398424ae41e" }
    ]
  }
}
```

### Email

```json
{ "Email": { "email": "ada@makenotion.com" } }
```

### Phone Number

```json
{ "Contact phone number": { "phone_number": "415-202-4776" } }
```

### URL

```json
{ "Website": { "url": "https://example.com" } }
```

Use `null` to unset a URL (not empty string).

### Files

```json
{
  "Blueprint": {
    "files": [
      {
        "name": "Project Alpha blueprint",
        "external": {
          "url": "https://www.figma.com/file/..."
        }
      }
    ]
  }
}
```

Files array **overwrites** the entire existing value on update.

### Relation

```json
{
  "Related tasks": {
    "relation": [
      { "id": "dd456007-6c66-4bba-957e-ea501dcda3a6" },
      { "id": "0c1f7cb2-8090-4f18-924e-d92965055e32" }
    ]
  }
}
```

The related data source's parent database must be **shared with the integration** for relations to resolve correctly.

### Properties you CANNOT set (Notion-generated)

- `rollup`
- `created_by`
- `created_time`
- `last_edited_by`
- `last_edited_time`
- `formula`

These are computed by Notion and will return an error if included in a create/update request.

---

## Templates

Instead of manually building content, you can apply a data source template.

### Step 1: List available templates

```bash
curl -X GET \
  'https://api.notion.com/v1/data_sources/<data_source_id>/templates' \
  -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
  -H 'Notion-Version: 2026-03-11'
```

Response:
```json
{
  "templates": [
    { "id": "a5da15f6-...", "name": "New Generic Task", "is_default": true },
    { "id": "9cc74169-...", "name": "New UI Task", "is_default": false }
  ],
  "has_more": false,
  "next_cursor": null
}
```

### Step 2: Create page with template

```json
{
  "parent": { "type": "data_source_id", "data_source_id": "<data_source_id>" },
  "properties": {
    "Task": {
      "title": [{ "type": "text", "text": { "content": "My New Task" } }]
    }
  },
  "template": {
    "type": "template_id",
    "template_id": "a5da15f6-b853-455d-8827-f906fb52db2b",
    "timezone": "America/New_York"
  }
}
```

Template options:
| `template[type]` | `template[template_id]` | `template[timezone]` | Behavior |
|---|---|---|---|
| `none` (default) | N/A | N/A | No template. Content from `content`/`children` applied immediately. |
| `default` | N/A | optional | Apply the data source's default template. `children` not allowed. |
| `template_id` | (UUID) | optional | Apply specific template. `children` not allowed. |

### Step 3: Wait for template processing

Template application is **asynchronous**. The API returns immediately with a blank page, then Notion populates content in the background.

For webhook-based integrations:
1. Listen for `page.created` and `page.content_updated` events
2. If `page.created` fires, call `GET /v1/blocks/<page_id>/children` to check if content is populated
3. If content is still blank, wait for `page.content_updated` event

---

## Discovery Workflow (Before Creating a Page)

To create a page in a data source, a Ruby library should follow this workflow:

### 1. Retrieve the data source schema

```
GET https://api.notion.com/v1/data_sources/<data_source_id>
```

This returns the `properties` object — the schema that all child pages must conform to.

```json
{
  "object": "data_source",
  "id": "c174b72c-d782-432f-8dc0-b647e1c96df6",
  "properties": {
    "Task": { "id": "title", "name": "Task", "type": "title", "title": {} },
    "Status": { "id": "Z%3ClH", "name": "Status", "type": "status", "status": { "options": [...] } },
    "Priority": { "id": "WPj^", "name": "Priority", "type": "number", "number": { "format": "number" } },
    "Due date": { "id": "M;Bw", "name": "Due date", "type": "date", "date": {} },
    "Tags": { "id": "QyRn", "name": "Tags", "type": "multi_select", "multi_select": { "options": [...] } }
  },
  "parent": { "type": "database_id", "database_id": "842a0286-..." }
}
```

### 2. Validate property values against schema

Before sending the create request, the library should:
- Check that each property key matches a property `name` (or `id`) in the data source schema
- Check that each property value conforms to the expected type
- Reject `rollup`, `created_by`, `created_time`, `last_edited_by`, `last_edited_time` (read-only)

### 3. Create the page

```
POST https://api.notion.com/v1/pages
```

---

## Ruby Library Design Notes

### Suggested API surface

```ruby
# Initialize client
client = Notion::Client.new(token: ENV["NOTION_API_KEY"])

# Discover data source schema
data_source = client.data_source.retrieve("c174b72c-d782-432f-8dc0-b647e1c96df6")
data_source.properties
# => { "Task" => <Notion::Property::Title>, "Status" => <Notion::Property::Status>, ... }

# Build a page with validated properties
page = client.pages.create(
  parent: { type: "data_source_id", data_source_id: "c174b72c-..." },
  properties: {
    "Task" => { title: [{ text: { content: "Fix login bug" } }] },
    "Status" => { status: { name: "In Progress" } },
    "Priority" => { number: 1 },
    "Tags" => { multi_select: [{ name: "urgent" }] }
  },
  content: [
    Notion::Blocks::Paragraph.new(text: "Description of the bug...")
  ]
)

# Or using a builder pattern for ergonomics
page = client.pages.build(data_source: "c174b72c-...") do |p|
  p.title "Fix login bug"
  p.status "In Progress"
  p.number "Priority", 1
  p.multi_select "Tags", ["urgent", "backend"]
  p.paragraph "Description of the bug..."
end.save
```

### Key implementation considerations

1. **Property validation**: The library should cache the data source schema and validate property types before sending requests. This avoids wasteful round-trips and gives clear error messages.

2. **Property identification**: Properties can be referenced by `name` (e.g., `"Task"`) or `id` (e.g., `"title"`, `"f%5C%5C%3Ap"`). The library should accept names for ergonomics and resolve to IDs internally.

3. **Auto-creating select options**: When setting a `multi_select` or `select` with an option name that doesn't exist, Notion will auto-create it (if the integration has write access). The library should document this behavior.

4. **Rich text helper**: The `rich_text` array structure is verbose. Provide a helper:
   ```ruby
   Notion.rich_text("Some text with {bold} and {code}")
   # => [{ type: "text", text: { content: "Some text with " }, annotations: {} }, ...]
   ```

5. **Pagination**: List endpoints return max 100 items per page. Use `start_cursor` and `has_more` for iteration.

6. **Error handling**:
   - `403` → Missing Insert Content capabilities
   - `400 validation_error` → Invalid property type, schema mismatch, or invalid template
   - `429 rate_limited` → Use the `Retry-After` header for retry logic
   - Always expose the `object`, `code`, `message`, and `request_id` from the [error payload](#error-payload-format).

7. **ID format**: UUIDs can be sent with or without dashes. The library should normalize.

8. **Markdown content**: When using the `markdown` parameter, newlines must be `\n` in JSON. In Ruby:
   ```ruby
   body = { markdown: "# Heading\n\nParagraph text" }.to_json
   # Ensure \n is preserved, not rendered as literal newline
   ```

9. **Icon and Cover**: These are top-level params (not nested under `properties`):
   ```ruby
   {
     icon: { type: "emoji", emoji: "📌" },
     cover: { type: "external", external: { url: "https://example.com/cover.jpg" } }
   }
   ```

10. **Webhook events for template pages**: If using templates, the page is returned blank. Set up webhook handlers for `page.created` / `page.content_updated` to know when content is ready.

---

## Related Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/v1/data_sources/<id>` | Get data source schema (properties) |
| `POST` | `/v1/data_sources/<id>/query` | Query pages in a data source |
| `GET` | `/v1/data_sources/<id>/templates` | List available templates |
| `GET` | `/v1/pages/<id>` | Retrieve a page |
| `PATCH` | `/v1/pages/<id>` | Update a page |
| `GET` | `/v1/blocks/<id>/children` | Get page content blocks |
| `PATCH` | `/v1/blocks/<id>/children` | Append blocks to a page |
| `POST` | `/v1/search` | Search across pages and databases |

---

## Sources

- https://developers.notion.com/reference/status-codes — Status codes
- https://developers.notion.com/reference/post-page — Create a page
- https://developers.notion.com/reference/database — Database object
- https://developers.notion.com/reference/data-source — Data source object
- https://developers.notion.com/reference/page — Page object
- https://developers.notion.com/reference/page-property-values — Page property types
- https://developers.notion.com/reference/intro — API conventions
- https://developers.notion.com/guides/data-apis/creating-pages-from-templates — Template guide
