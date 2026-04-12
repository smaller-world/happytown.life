# Tally API Research

## Overview
Tally provides a RESTful API for managing forms, submissions, and related data. The API uses Bearer token authentication and returns JSON responses.

**Base URL:** `https://api.tally.so`

**Developer Docs:** https://developers.tally.so/api-reference/endpoint/forms/list

## Authentication
All API requests require Bearer token authentication:

```
Authorization: Bearer <token>
```

API keys are generated from the [Tally API Keys Dashboard](https://tally.so/settings/api-keys). Each key is tied to a specific API version by default.

## API Versioning

Tally uses date-based versioning (inspired by Stripe):

- **Default:** API key is tied to a specific version at creation time
- **Override per request:** Use the `tally-version` header to specify a version
- **Latest version:** Rotate your API key to use the latest version by default

### Example with Version Header
```bash
curl -X GET 'https://api.tally.so/forms' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -H 'tally-version: 2025-02-01'
```

### Key Versions
- **2025-01-15:** Initial API launch (responses returned directly as array)
- **2025-02-01:** Breaking changes introduced pagination metadata; responses wrapped in `items` key with pagination info

## Endpoints

### List Forms
Returns a paginated array of form objects.

**Endpoint:** `GET /forms`

**Query Parameters:**
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 50, max: 500)
- `workspaceIds` (string[]): Filter by workspace IDs (URL-encoded)

**Response:**
```json
{
  "items": [
    {
      "id": "LmBenY",
      "name": "Test",
      "isNameModifiedByUser": false,
      "workspaceId": "kwob3J",
      "organizationId": "kwob3J",
      "status": "PUBLISHED",
      "hasDraftBlocks": false,
      "numberOfSubmissions": 0,
      "createdAt": "2025-01-28T09:23:24.000Z",
      "updatedAt": "2025-01-28T09:41:22.000Z",
      "index": 0,
      "isClosed": false
    }
  ],
  "page": 1,
  "limit": 50,
  "total": 2,
  "hasMore": false
}
```

### List Form Submissions
Returns a paginated list of form submissions with their responses.

**Endpoint:** `GET /forms/{formId}/submissions`

**Path Parameters:**
- `formId` (string, required): The ID of the form

**Query Parameters:**
- `page` (number): Page number (default: 1)
- `limit` (number): Submissions per page (default: 50, max: 500, range: 1-500)
- `filter` (enum): Filter by status — `all`, `completed`, `partial`
- `startDate` (string, date-time): Filter submissions on or after this date (ISO 8601)
- `endDate` (string, date-time): Filter submissions on or before this date (ISO 8601)
- `afterId` (string): Get submissions after a specific submission ID (cursor-based pagination)

**Response:**
```json
{
  "page": 1,
  "limit": 50,
  "hasMore": true,
  "totalNumberOfSubmissionsPerFilter": { ... },
  "questions": [
    {
      "key": "question_3EKz4n",
      "label": "Text",
      "type": "INPUT_TEXT"
    }
  ],
  "submissions": [
    {
      "responseId": "2wgx4n",
      "submissionId": "2wgx4n",
      "respondentId": "dwQ4n",
      "formId": "VwbNEw",
      "createdAt": "2023-06-28T15:00:21.000Z",
      "fields": [
        {
          "key": "question_3EKz4n",
          "label": "Text",
          "type": "INPUT_TEXT",
          "value": "Hello"
        }
      ]
    }
  ]
}
```

**Field Object Structure:**
- `key`: Unique identifier for the question/field
- `label`: The question text or label
- `type`: The type of field (e.g., `INPUT_TEXT`, `INPUT_EMAIL`, `MULTIPLE_CHOICE`, etc.)
- `value`: The submitted value (type varies by field type)
- `options`: (Optional) List of available options for choice-based fields

**Field Types and Value Formats:**

| Type | Value Format |
|------|--------------|
| `INPUT_TEXT` | String |
| `INPUT_NUMBER` | Number |
| `INPUT_EMAIL` | String |
| `INPUT_DATE` | String (YYYY-MM-DD) |
| `CHECKBOXES` | Boolean (for specific options) or Array of IDs |
| `MULTIPLE_CHOICE` | Array of selected option IDs |
| `FILE_UPLOAD` | Array of objects with `id`, `name`, `url`, `mimeType`, `size` |
| `HIDDEN_FIELDS` | String |
| `CALCULATED_FIELDS` | String or Number |

### Get Single Submission
Returns a specific form submission with all its responses and the form questions.

**Endpoint:** `GET /forms/{formId}/submissions/{submissionId}`

### List Form Questions
Returns a list of form questions with their fields.

**Endpoint:** `GET /forms/{formId}/questions`

## Pagination Strategy

### Offset-Based Pagination
- Use `page` and `limit` parameters
- Response includes `hasMore` boolean to indicate if more pages exist
- Default page size: 50, maximum: 500

### Cursor-Based Pagination (Submissions Only)
- Use `afterId` parameter for efficient pagination
- Useful for real-time polling to get only new submissions
- Pass the last submission ID from the previous request

**Example:**
```bash
# First request
GET /forms/{formId}/submissions?limit=50

# Subsequent request (only new submissions)
GET /forms/{formId}/submissions?afterId=<last_submission_id>
```

## Rate Limiting
Tally implements rate limiting. If you exceed the limit, you'll receive a 429 status code. Use exponential backoff for retries.

## Best Practices

1. **Use Webhooks for Real-Time Updates:** The most efficient way to receive new submissions is via webhooks rather than polling. Webhooks deliver data instantly when a form is submitted.

2. **Pagination:** Use `hasMore` in the response to determine if you need to fetch additional pages.

3. **Filtering:** Use `startDate`, `endDate`, and `filter` parameters to reduce the amount of data transferred.

4. **Cursor-Based Pagination:** For polling scenarios, prefer `afterId` over offset-based pagination to avoid duplicates and improve efficiency.

5. **Versioning:** Always specify `tally-version` header explicitly if you need consistent behavior, or rotate API keys to use the latest version.

## Error Handling
Standard HTTP status codes:
- `200`: Success
- `400`: Bad Request
- `401`: Unauthorized (invalid or missing API key)
- `404`: Not Found
- `429`: Too Many Requests (rate limited)
- `500`: Internal Server Error

## Testing and Development
- **Request Inspector:** Use [Request Inspector](https://requestinspector.com/) to inspect live API responses
- **Tally API Keys Dashboard:** https://tally.so/settings/api-keys

## Implementation Notes for `Tally::Client`

When building `lib/tally.rb`:

1. **Authentication:** Accept API key via configuration or environment variable; use `Bearer` token in `Authorization` header

2. **Pagination:** Implement a method that handles pagination automatically or yields pages:
   - Track `hasMore` and increment `page` until all results are fetched
   - Support both offset (`page`/`limit`) and cursor (`afterId`) pagination

3. **Response Parsing:** Parse the response structure (v2025-02-01+):
   - Extract `submissions` array
   - Include `questions` array for field metadata
   - Track pagination state (`page`, `limit`, `hasMore`)

4. **Filtering:** Support optional filters:
   - Date range (`startDate`, `endDate`)
   - Status filter (`all`, `completed`, `partial`)

5. **Version Header:** Use `tally-version` header to ensure consistent behavior

### Example Client Interface (Ruby)
```ruby
module Tally
  class Client
    def initialize(api_key:, version: "2025-02-01")
      @api_key = api_key
      @version = version
    end

    def list_submissions(form_id, page: 1, limit: 50, filter: "all", start_date: nil, end_date: nil, after_id: nil)
      # Returns paginated submissions
    end

    def list_submissions_all(form_id, **filters)
      # Enumerator that yields all submissions across pages
    end

    def list_forms(workspace_ids: nil, page: 1, limit: 50)
      # Returns paginated forms
    end
  end
end
```
