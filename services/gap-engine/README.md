# Gap Engine

Gap engine identifies missing connections and potential research gaps in the knowledge graph.

Responsibilities
- Run periodic analysis over the knowledge graph to find under-connected topics.
- Provide endpoints to query suggested gaps and scoring explanations.
- Publish gap.suggestion.created events.

Architecture
- Python service using FastAPI and background workers.

API
- GET /api/v1/gaps?topic={topic}

Environment
- GAP_PORT=8085

Run locally
- pip install -r requirements.txt
- uvicorn services.gap-engine.src.main:app --port ${GAP_PORT:-8085}
