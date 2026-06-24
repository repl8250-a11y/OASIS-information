# Monitoring Service

Centralized monitoring ingestion and health orchestration. Collects custom metrics and forwards them to Prometheus/Grafana.

Responsibilities
- Receive metrics and health pings from services
- Provide a single-source-of-truth for alerts and synthetic checks

Architecture
- Go service for efficient ingestion

API
- POST /api/v1/metrics

Environment
- MONITOR_PORT=8092
