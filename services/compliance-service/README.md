# Compliance Service

Compliance service manages audits, access logs, and retention policies for regulated data.

Responsibilities
- Store immutable audit logs
- Manage data retention policies and purge tasks
- Provide compliance reports and export endpoints

Architecture
- Python FastAPI
- Uses append-only storage pattern for audits (Postgres)

API
- GET /api/v1/compliance/reports

Environment
- COMPLIANCE_PORT=8089
