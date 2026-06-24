# Novelty Engine

The novelty engine scores incoming content for novelty relative to existing indexed content. It is used to prioritize items for human review or surfacing.

Responsibilities
- Consume paper.ingested events and compute novelty score using embeddings and heuristics.
- Expose HTTP endpoints for batch scoring and model health.
- Publish novelty.score.created events.

Architecture
- Python FastAPI service.
- Depends on knowledge-graph-service for graph signals and vector store for nearest neighbor computations.
- Runs background workers for heavy compute tasks.

API
- POST /api/v1/novelty/score - provide document id or embedding to compute score

Environment
- NOVELTY_PORT=8084
- NOVELTY_KAFKA_BROKERS
- NOVELTY_DATABASE_URL

Run locally
- pip install -r requirements.txt
- uvicorn services.novelty_engine.src.main:app --port ${NOVELTY_PORT:-8084}
