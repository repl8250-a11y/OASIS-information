# Webhooks

## Overview

Webhooks allow your application to receive real-time notifications about events in OASIS.

## Setting Up Webhooks

### 1. Register Webhook Endpoint

```bash
curl -X POST https://api.oasis.io/v1/webhooks \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app.com/webhooks/oasis",
    "events": [
      "resource.created",
      "resource.updated",
      "resource.deleted",
      "comment.created"
    ],
    "active": true
  }'
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "id": "webhook-123",
    "url": "https://your-app.com/webhooks/oasis",
    "events": ["resource.created", "resource.updated", "resource.deleted", "comment.created"],
    "active": true,
    "created_at": "2026-06-24T10:30:00Z"
  }
}
```

### 2. Receive Webhook Events

Your endpoint will receive POST requests with event data:

```json
{
  "id": "event-789",
  "type": "resource.created",
  "timestamp": "2026-06-24T10:30:00Z",
  "data": {
    "id": "resource-456",
    "name": "New Document",
    "type": "document",
    "owner_id": "user-123"
  }
}
```

### 3. Verify Webhook Signature

All webhooks include a signature header for verification:

**Header:**
```
X-Webhook-Signature: sha256=abcd1234efgh5678ijkl9012mnop3456
```

**Verify (Node.js):**
```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(`sha256=${hash}`),
    Buffer.from(signature)
  );
}

// In your webhook endpoint
app.post('/webhooks/oasis', (req, res) => {
  const signature = req.headers['x-webhook-signature'];
  const secret = process.env.WEBHOOK_SECRET;
  
  if (!verifyWebhookSignature(req.body, signature, secret)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  
  // Process webhook
  handleEvent(req.body);
  res.status(200).json({ received: true });
});
```

---

## Webhook Events

### resource.created

Triggered when a new resource is created.

```json
{
  "id": "evt_123",
  "type": "resource.created",
  "timestamp": "2026-06-24T10:30:00Z",
  "data": {
    "id": "resource-456",
    "name": "My Document",
    "type": "document",
    "owner_id": "user-123",
    "status": "draft",
    "visibility": "private"
  }
}
```

---

### resource.updated

Triggered when a resource is modified.

```json
{
  "id": "evt_124",
  "type": "resource.updated",
  "timestamp": "2026-06-24T10:35:00Z",
  "data": {
    "id": "resource-456",
    "name": "My Updated Document",
    "type": "document",
    "updated_fields": ["name", "status"],
    "previous_values": {
      "name": "My Document",
      "status": "draft"
    }
  }
}
```

---

### resource.deleted

Triggered when a resource is deleted.

```json
{
  "id": "evt_125",
  "type": "resource.deleted",
  "timestamp": "2026-06-24T10:40:00Z",
  "data": {
    "id": "resource-456",
    "name": "My Document",
    "deleted_by": "user-123"
  }
}
```

---

### resource.published

Triggered when a resource is published.

```json
{
  "id": "evt_126",
  "type": "resource.published",
  "timestamp": "2026-06-24T10:45:00Z",
  "data": {
    "id": "resource-456",
    "name": "My Document",
    "published_at": "2026-06-24T10:45:00Z"
  }
}
```

---

### comment.created

Triggered when a comment is added.

```json
{
  "id": "evt_127",
  "type": "comment.created",
  "timestamp": "2026-06-24T10:50:00Z",
  "data": {
    "id": "comment-789",
    "resource_id": "resource-456",
    "author_id": "user-456",
    "content": "Great document!",
    "mentions": ["user-123"]
  }
}
```

---

### permission.changed

Triggered when permissions are modified.

```json
{
  "id": "evt_128",
  "type": "permission.changed",
  "timestamp": "2026-06-24T10:55:00Z",
  "data": {
    "resource_id": "resource-456",
    "user_id": "user-789",
    "new_role": "editor",
    "previous_role": "viewer",
    "changed_by": "user-123"
  }
}
```

---

## Retry Policy

Failed webhook deliveries are retried automatically:

```
Attempt 1: Immediate
Attempt 2: 5 minutes
Attempt 3: 30 minutes
Attempt 4: 2 hours
Attempt 5: 24 hours
```

After 5 failed attempts, the webhook is disabled. You can re-enable it manually.

---

## Webhook Management

### List Webhooks

```bash
curl -X GET https://api.oasis.io/v1/webhooks \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Update Webhook

```bash
curl -X PUT https://api.oasis.io/v1/webhooks/webhook-123 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "events": ["resource.created", "resource.updated"],
    "active": true
  }'
```

### Delete Webhook

```bash
curl -X DELETE https://api.oasis.io/v1/webhooks/webhook-123 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Test Webhook

```bash
curl -X POST https://api.oasis.io/v1/webhooks/webhook-123/test \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Sends a test event to your webhook endpoint.

---

## Best Practices

1. **Verify Signatures**: Always verify webhook signatures
2. **Handle Duplicates**: Webhooks may be delivered multiple times
3. **Idempotent Processing**: Make webhook handlers idempotent
4. **Fast Response**: Respond quickly (within 5 seconds)
5. **Queue Processing**: Use async queues for heavy processing
6. **Log Events**: Keep logs of all webhook events
7. **Monitor Health**: Check webhook delivery status regularly
8. **Error Handling**: Handle errors gracefully

### Idempotent Processing Example

```javascript
async function handleWebhook(event) {
  // Check if already processed
  const processed = await db.query(
    'SELECT id FROM webhook_events WHERE event_id = ?',
    [event.id]
  );
  
  if (processed.length > 0) {
    console.log('Event already processed:', event.id);
    return;
  }
  
  // Process event
  await processEvent(event);
  
  // Record as processed
  await db.query(
    'INSERT INTO webhook_events (event_id, processed_at) VALUES (?, NOW())',
    [event.id]
  );
}
```

---

## Troubleshooting

### Webhooks Not Received

1. Check webhook is active
2. Verify endpoint is accessible from internet
3. Check firewall/security settings
4. Review webhook logs for errors
5. Test webhook manually

### Signature Verification Fails

1. Ensure secret is correct
2. Verify webhook body is not modified
3. Check timestamp hasn't expired
4. Verify hash algorithm is SHA256

### Delivery Issues

1. Ensure endpoint responds within 5 seconds
2. Return HTTP 200 on successful processing
3. Check logs for network errors
4. Verify webhook URL is correct
5. Check rate limiting

---

## Examples

### Python

```python
from flask import Flask, request
import hmac
import hashlib

app = Flask(__name__)
WEBHOOK_SECRET = 'your-webhook-secret'

@app.route('/webhooks/oasis', methods=['POST'])
def handle_webhook():
    # Verify signature
    signature = request.headers.get('X-Webhook-Signature')
    payload = request.get_data()
    
    expected_sig = 'sha256=' + hmac.new(
        WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    if not hmac.compare_digest(signature, expected_sig):
        return {'error': 'Invalid signature'}, 401
    
    # Process event
    event = request.json
    
    if event['type'] == 'resource.created':
        handle_resource_created(event['data'])
    elif event['type'] == 'comment.created':
        handle_comment_created(event['data'])
    
    return {'received': True}, 200

def handle_resource_created(data):
    print(f"New resource created: {data['name']}")
    # Your logic here

def handle_comment_created(data):
    print(f"New comment: {data['content']}")
    # Your logic here

if __name__ == '__main__':
    app.run(port=5000)
```

---
*Last Updated: 2026-06-24*
