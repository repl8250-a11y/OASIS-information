# SDK & Libraries

## Overview

Official SDKs are available for popular programming languages and frameworks.

## Installation

### JavaScript/TypeScript

```bash
npm install @oasis/sdk
# or
yarn add @oasis/sdk
```

**Quick Start:**
```typescript
import { OasisClient } from '@oasis/sdk';

const client = new OasisClient({
  apiKey: 'your-api-key',
  baseUrl: 'https://api.oasis.io/v1'
});

// Login
const auth = await client.auth.login({
  email: 'user@example.com',
  password: 'password'
});

// Create resource
const resource = await client.resources.create({
  name: 'My Document',
  type: 'document',
  content: { body: 'Hello World' }
});

// Search
const results = await client.search.query('tutorial', {
  type: 'document',
  limit: 20
});
```

---

### Python

```bash
pip install oasis-sdk
```

**Quick Start:**
```python
from oasis import OasisClient

client = OasisClient(
    api_key='your-api-key',
    base_url='https://api.oasis.io/v1'
)

# Login
auth = client.auth.login(
    email='user@example.com',
    password='password'
)

# Create resource
resource = client.resources.create(
    name='My Document',
    type='document',
    content={'body': 'Hello World'}
)

# Search
results = client.search.query('tutorial', type='document', limit=20)
```

---

### Go

```bash
go get github.com/oasis-io/sdk-go
```

**Quick Start:**
```go
package main

import "github.com/oasis-io/sdk-go"

func main() {
    client := sdk.NewClient(
        "your-api-key",
        "https://api.oasis.io/v1",
    )

    // Login
    auth, err := client.Auth.Login(ctx, sdk.LoginRequest{
        Email:    "user@example.com",
        Password: "password",
    })

    // Create resource
    resource, err := client.Resources.Create(ctx, sdk.CreateResourceRequest{
        Name:    "My Document",
        Type:    "document",
        Content: map[string]interface{}{"body": "Hello World"},
    })

    // Search
    results, err := client.Search.Query(ctx, "tutorial", sdk.SearchOptions{
        Type:  "document",
        Limit: 20,
    })
}
```

---

### Java

```xml
<dependency>
    <groupId>io.oasis</groupId>
    <artifactId>oasis-sdk</artifactId>
    <version>1.0.0</version>
</dependency>
```

**Quick Start:**
```java
import io.oasis.sdk.OasisClient;
import io.oasis.sdk.models.*;

public class Example {
    public static void main(String[] args) {
        OasisClient client = new OasisClient(
            "your-api-key",
            "https://api.oasis.io/v1"
        );

        // Login
        AuthResponse auth = client.getAuth().login(new LoginRequest(
            "user@example.com",
            "password"
        ));

        // Create resource
        Resource resource = client.getResources().create(new CreateResourceRequest()
            .setName("My Document")
            .setType("document")
            .setContent(Map.of("body", "Hello World"))
        );

        // Search
        SearchResults results = client.getSearch().query("tutorial",
            new SearchOptions().setType("document").setLimit(20)
        );
    }
}
```

---

### Ruby

```bash
gem install oasis
```

**Quick Start:**
```ruby
require 'oasis'

client = Oasis::Client.new(
  api_key: 'your-api-key',
  base_url: 'https://api.oasis.io/v1'
)

# Login
auth = client.auth.login(
  email: 'user@example.com',
  password: 'password'
)

# Create resource
resource = client.resources.create(
  name: 'My Document',
  type: 'document',
  content: { body: 'Hello World' }
)

# Search
results = client.search.query('tutorial', type: 'document', limit: 20)
```

---

## Authentication

### API Key Authentication

```typescript
const client = new OasisClient({
  apiKey: 'sk_live_xxxxxxxxxxxxx'
});
```

### OAuth 2.0

```typescript
const client = new OasisClient({
  clientId: 'your-client-id',
  clientSecret: 'your-client-secret',
  redirectUri: 'https://your-app.com/callback'
});

// Get authorization URL
const authUrl = client.getAuthorizationUrl();

// Exchange code for token
const token = await client.exchangeCode(code);
```

### Bearer Token

```typescript
const client = new OasisClient({
  token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
});
```

---

## Common Patterns

### Handling Errors

```typescript
try {
  const resource = await client.resources.get('resource-id');
} catch (error) {
  if (error.code === 'RESOURCE_NOT_FOUND') {
    console.log('Resource does not exist');
  } else if (error.code === 'INSUFFICIENT_PERMISSIONS') {
    console.log('Access denied');
  } else {
    console.error('Unexpected error:', error);
  }
}
```

### Pagination

```typescript
let page = 1;
let hasMore = true;

while (hasMore) {
  const result = await client.resources.list({
    page: page,
    limit: 50
  });

  console.log(result.data);
  hasMore = result.pagination.has_next;
  page++;
}
```

### Retry Logic

```typescript
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => 
        setTimeout(resolve, Math.pow(2, i) * 1000)
      );
    }
  }
}

const resource = await retryWithBackoff(() => 
  client.resources.get('resource-id')
);
```

### Batch Operations

```typescript
const resourceIds = ['id-1', 'id-2', 'id-3'];

const resources = await Promise.all(
  resourceIds.map(id => client.resources.get(id))
);
```

---

## Webhooks

### Setting Up Webhooks

```typescript
const webhook = await client.webhooks.create({
  url: 'https://your-app.com/webhooks/oasis',
  events: ['resource.created', 'resource.updated'],
  secret: 'webhook-secret'
});
```

### Verifying Webhook Signature

```typescript
import crypto from 'crypto';

function verifyWebhookSignature(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(hash),
    Buffer.from(signature)
  );
}
```

---

## Rate Limiting

SDKs automatically handle rate limiting with exponential backoff:

```typescript
const client = new OasisClient({
  apiKey: 'your-api-key',
  retryConfig: {
    maxRetries: 3,
    initialDelayMs: 1000,
    backoffMultiplier: 2
  }
});
```

---

## Logging & Debugging

### Enable Debug Logging

```typescript
const client = new OasisClient({
  apiKey: 'your-api-key',
  debug: true,
  logger: console
});
```

### Custom Logging

```typescript
const client = new OasisClient({
  apiKey: 'your-api-key',
  logger: {
    debug: (msg) => console.log(`[DEBUG] ${msg}`),
    info: (msg) => console.log(`[INFO] ${msg}`),
    warn: (msg) => console.warn(`[WARN] ${msg}`),
    error: (msg) => console.error(`[ERROR] ${msg}`)
  }
});
```

---

## Type Safety

### TypeScript

Full TypeScript support with complete type definitions:

```typescript
import { 
  Resource, 
  SearchOptions, 
  SearchResults 
} from '@oasis/sdk';

const options: SearchOptions = {
  type: 'document',
  limit: 20,
  sort: 'date' // Type-checked, only valid options allowed
};

const results: SearchResults = await client.search.query('query', options);
```

---

## Contributing

To report issues or contribute to SDKs:

1. **Report Bugs**: Open issue on respective SDK repository
2. **Suggest Features**: Use feature request template
3. **Submit PR**: Fork, create branch, submit pull request
4. **Maintain Code**: Follow SDK coding standards and tests

SDK Repositories:
- JavaScript: https://github.com/oasis-io/sdk-js
- Python: https://github.com/oasis-io/sdk-python
- Go: https://github.com/oasis-io/sdk-go
- Java: https://github.com/oasis-io/sdk-java
- Ruby: https://github.com/oasis-io/sdk-ruby

---
*Last Updated: 2026-06-24*
