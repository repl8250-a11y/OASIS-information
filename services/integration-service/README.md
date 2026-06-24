# Integration Service

Acts as a connector hub to third-party systems (Crossref, arXiv, external crawlers) and implements reliable polling and webhooks.

Responsibilities
- Manage connectors, credentials, and polling schedules
- Normalize third-party responses and emit standardized events

Architecture
- Python FastAPI

API
- POST /api/v1/connectors

Environment
- INTEGRATION_PORT=8093
