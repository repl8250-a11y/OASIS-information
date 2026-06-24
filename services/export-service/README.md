# Export Service

Responsible for exporting datasets, reports, and bulk downloads.

Responsibilities
- Create export jobs, manage status, generate CSV/NDJSON/Parquet
- Store export artifacts in object storage and provide signed URLs
- Emit export.job.completed events

Architecture
- Python FastAPI service with background workers

API
- POST /api/v1/exports
- GET /api/v1/exports/{id}/status

Environment
- EXPORT_PORT=8091
