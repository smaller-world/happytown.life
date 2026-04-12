# Tally Webhook Research

## Overview
Tally webhooks allow you to receive real-time notifications when a form is submitted. Data is sent as a **POST** request with a **JSON** payload to a configured endpoint.

## Endpoint Requirements
- **Method:** POST
- **Content-Type:** `application/json`
- **Response:** Must return a successful status code (2XX) within **10 seconds**.
- **Timeout:** If processing takes longer than 10 seconds, it is recommended to handle processing asynchronously (e.g., via a background job) to respond to Tally quickly.

## Security
- **Signing Secret:** You can verify that a request came from Tally using a signing secret.
- **Header:** `Tally-Signature`
- **Verification:** The header contains a SHA256 HMAC hash of the webhook payload, signed with your secret.
- **Example Verification (Node.js):**
  ```typescript
  const calculatedSignature = createHmac('sha256', yourSigningSecret)
    .update(JSON.stringify(webhookPayload))
    .digest('base64');
  ```

## Payload Structure
The payload consists of metadata (`eventId`, `eventType`, `createdAt`) and a `data` object containing the response details.

### Top-level Fields
- `eventId`: Unique identifier for the event.
- `eventType`: Always `FORM_RESPONSE` for submissions.
- `createdAt`: ISO timestamp of the event.
- `data`: Object containing the submission data.

### Data Object
- `responseId` / `submissionId`: Unique ID for the submission.
- `respondentId`: Unique ID for the respondent.
- `formId`: ID of the Tally form.
- `formName`: Name of the form.
- `createdAt`: Submission timestamp.
- `fields`: An array of field objects.

### Field Object Structure
Each field in the `fields` array typically contains:
- `key`: Unique identifier for the question/field.
- `label`: The question text or label.
- `type`: The type of field (e.g., `INPUT_TEXT`, `INPUT_EMAIL`, `MULTIPLE_CHOICE`, etc.).
- `value`: The submitted value (type varies by field type).
- `options`: (Optional) List of available options for choice-based fields.

## Example Payload
Below is an example of a full webhook payload from Tally.

```json
{
  "eventId": "a4cb511e-d513-4fa5-baee-b815d718dfd1",
  "eventType": "FORM_RESPONSE",
  "createdAt": "2023-06-28T15:00:21.889Z",
  "data": {
    "responseId": "2wgx4n",
    "submissionId": "2wgx4n",
    "respondentId": "dwQKYm",
    "formId": "VwbNEw",
    "formName": "Webhook payload",
    "createdAt": "2023-06-28T15:00:21.000Z",
    "fields": [
      {
        "key": "question_3EKz4n",
        "label": "Text",
        "type": "INPUT_TEXT",
        "value": "Hello"
      },
      {
        "key": "question_w4Q4Xn",
        "label": "Email",
        "type": "INPUT_EMAIL",
        "value": "alice@example.com"
      },
      {
        "key": "question_3qL4Gm",
        "label": "Multiple choice",
        "type": "MULTIPLE_CHOICE",
        "value": [
          "e7bfbbc6-c2e6-4821-8670-72ed1cb31cd5"
        ],
        "options": [
          {
            "id": "e7bfbbc6-c2e6-4821-8670-72ed1cb31cd5",
            "text": "In progress"
          }
        ]
      },
      {
        "key": "question_nW2ONw",
        "label": "File upload",
        "type": "FILE_UPLOAD",
        "value": [
          {
            "id": "5mDNqw",
            "name": "Tally_Icon.png",
            "url": "https://storage.googleapis.com/tally-response-assets-dev/vBXMXN/34fd1ee5-4ead-4929-9a4a-918ac9f0b416/Tally_Icon.png",
            "mimeType": "image/png",
            "size": 16233
          }
        ]
      }
    ]
  }
}
```

## Field Types & Values
| Type | Value Format |
| --- | --- |
| `INPUT_TEXT` | String |
| `INPUT_NUMBER` | Number |
| `INPUT_EMAIL` | String |
| `INPUT_DATE` | String (YYYY-MM-DD) |
| `CHECKBOXES` | Boolean (for specific options) or Array of IDs |
| `MULTIPLE_CHOICE` | Array of selected option IDs |
| `FILE_UPLOAD` | Array of objects with `id`, `name`, `url`, `mimeType`, `size` |
| `HIDDEN_FIELDS` | String |
| `CALCULATED_FIELDS` | String or Number |

## Retries
If the endpoint does not return a 2XX code within 10 seconds, Tally retries:
1. After 5 minutes
2. After 30 minutes
3. After 1 hour
4. After 6 hours
5. After 1 day

## Testing Tools
- [Request Inspector](https://requestinspector.com/) can be used to inspect live webhook payloads.
