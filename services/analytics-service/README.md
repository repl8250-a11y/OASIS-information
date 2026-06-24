# Analytics Service

Aggregates events and provides analytics pipelines and dashboards.

Responsibilities
- Consume Kafka events and write to analytics store (ClickHouse/BigQuery)
- Provide aggregation APIs and query endpoints for dashboards
- Manage pipeline schema evolution

Architecture
- Python service with async consumers and batching

API
- GET /api/v1/analytics/metrics

Environment
- ANALYTICS_PORT=8090
