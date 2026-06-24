# Discovery Service

Discovery service discovers new sources of content (web crawlers, RSS, integrations) and schedules ingestion tasks.

Responsibilities
- Crawl configured sources on schedule.
- Normalize source metadata and hand off to ingestion pipelines (paper-service).
- Expose endpoints to register sources and view crawl status.
- Emit events: discovery.source.discovered, discovery.crawl.completed.

Architecture
- Written in Go to allow efficient concurrency and small container footprint.
- Uses Redis for scheduling and deduplication, Postgres for persistent source metadata.
- Publishes events to Kafka for downstream processing.

API (HTTP)
- POST /api/v1/sources - register a new source
- GET /api/v1/sources/{id} - fetch source metadata
- POST /api/v1/crawl/{id}/start - trigger crawl

Health & Metrics
- /api/v1/health, /api/v1/ready, /metrics

Environment variables
- DISCOVERY_PORT=8083
- DISCOVERY_DATABASE_URL
- DISCOVERY_REDIS_URL
- DISCOVERY_KAFKA_BROKERS

Run locally
- go build ./...
- ./discovery-service
