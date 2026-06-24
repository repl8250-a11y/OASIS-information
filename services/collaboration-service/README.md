# Collaboration Service

Handles shared workspaces, annotations, comments, and collaborative document sessions.

Responsibilities
- Store comments, annotations, and collaboration sessions.
- Manage permissions and collaborative locks.
- Emit events: collaboration.comment.created, collaboration.session.started.

Architecture
- Python FastAPI service with WebSocket support for live collaboration.
- Postgres for persistent data and Redis for ephemeral session state.

API
- POST /api/v1/comments
- GET /api/v1/sessions/{id}

Environment
- COLLAB_PORT=8087

Run locally
- pip install -r requirements.txt
- uvicorn services/collaboration-service.src.main:app --port ${COLLAB_PORT:-8087}
