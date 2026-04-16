# Luma API Research - Single Event Retrieval

## Endpoint
`GET /v1/event/get`

## Parameters
- `id`: The event ID (e.g., `evt-...`).

## Response Structure
The response returns a JSON object with `event` and `hosts` keys. Notably, `tags` are nested within the `event` object.

### Example Response
```json
{
  "event": {
    "id": "evt-OjQC5jEt3ySXDGO",
    "api_id": "evt-OjQC5jEt3ySXDGO",
    "name": "the mindful miles #94: we're back in High Park!",
    "description": "...",
    "description_md": "...",
    "start_at": "2026-04-18T12:30:00.000Z",
    "end_at": "2026-04-18T15:00:00.000Z",
    "timezone": "America/Toronto",
    "geo_address_json": { ... },
    "geo_latitude": "43.651557",
    "geo_longitude": "-79.4514248",
    "url": "https://luma.com/hta6p8ft",
    "tags": [
      {
        "id": "tag-XRCUFkgLqcr3E0l",
        "api_id": "tag-XRCUFkgLqcr3E0l",
        "name": "mindful miles"
      }
    ],
    ...
  },
  "hosts": [ ... ]
}
```

## Integration Notes
- The `tags` placement differs from `list-events` (where they are siblings to `event` in an `entry`).
- For the `Luma::Client` implementation, we can map this into the existing `Luma::EventEntry` structure to maintain compatibility with `Event.upsert_from_luma_entry`.
