ResearchOS API Documentation

Overview

ResearchOS exposes a unified API layer that provides access to research discovery, paper management, knowledge graph exploration, novelty analysis, research gap detection, collaboration workflows, and programmatic integration points for enterprise customers. The API is designed for stability, observability, and backward compatibility across releases.

The API follows a service-oriented architecture while presenting a unified developer experience through the API Gateway.

---

Base URL

Development

http://localhost:8000/api

Staging

https://staging-api.researchos.ai

Production

https://api.researchos.ai

---

API Principles

ResearchOS APIs follow these principles:

- REST-first architecture for public surfaces, with gRPC available for high-throughput internal RPCs
- JSON request and response format for HTTP endpoints
- Stateless authentication with short-lived JWTs and refresh tokens
- Consistent error handling using a canonical error envelope
- Pagination for large datasets, with cursor support for deep pagination
- Versioned endpoints and explicit deprecation policy
- Idempotent write operations where applicable

---

Service Domains

Authentication

Responsible for:

- User registration
- Login
- OAuth providers
- Session management
- Multi-factor authentication
- Access tokens

Base Path:

/api/auth

---

User Management

Responsible for:

- User profiles
- Preferences
- Research interests
- Notification settings
- Account management

Base Path:

/api/users

---

Discovery

Responsible for:

- Paper discovery
- Semantic search
- Citation search
- Author search
- Institution search
- Topic exploration

Base Path:

/api/discovery

---

Papers

Responsible for:

- Paper metadata
- Full text retrieval
- PDF processing
- Citation information
- References
- Versions

Base Path:

/api/papers

---

Knowledge Graph

Responsible for:

- Entity exploration
- Relationship discovery
- Author networks
- Topic graphs
- Institution graphs

Base Path:

/api/knowledge-graph

---

Novelty Engine

Responsible for:

- Novelty scoring
- Similarity detection
- Prior work analysis
- Innovation assessment

Base Path:

/api/novelty

---

Gap Engine

Responsible for:

- Research gap detection
- Opportunity identification
- Missing linkage discovery
- Future direction analysis

Base Path:

/api/gaps

---

AI Copilot

Responsible for:

- Research assistance
- Question answering
- Literature synthesis
- Citation generation
- Insight generation

Base Path:

/api/copilot

---

Authentication

All protected endpoints require:

Authorization: Bearer <token>

Authentication flow documentation:

See:

docs/api/authentication.md

---

Response Format

Success Response

{
  "success": true,
  "data": {},
  "meta": {
    "requestId": "req_xxx",
    "timestamp": "2026-01-01T00:00:00Z"
  }
}

Error Response

{
  "success": false,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Requested resource was not found"
  }
}

---

Pagination

Paginated endpoints return:

{
  "items": [],
  "total": 1200,
  "page": 1,
  "pageSize": 20,
  "hasMore": true
}

Query Parameters

?page=1
&pageSize=20

---

Rate Limiting

Default limits:

Free Tier

- 100 requests/minute

Research Tier

- 1000 requests/minute

Enterprise Tier

- Custom limits

Rate limit headers:

X-RateLimit-Limit
X-RateLimit-Remaining
X-RateLimit-Reset

---

API Versioning

Versioning strategy:

/api/v1/...

Future versions:

/api/v2/...

Backward compatibility is maintained whenever possible.

---

Health Endpoints

Gateway

GET /health

Service Health

GET /api/system/health

Readiness

GET /api/system/ready

Liveness

GET /api/system/live

---

SDK Support

Official SDKs

- TypeScript
- Python
- Go

Future SDKs

- Java
- Rust
- C#

---

OpenAPI Specification

Complete machine-readable API specification:

docs/api/openapi.yaml
