# Knowledge Graph Service

The Knowledge Graph Service provides persistent storage and query endpoints for interconnected entities (nodes and edges) used across the OASIS platform. It supports ingestion, indexing, search, an[...] 

Primary responsibilities
- Persist node and edge documents in a graph-aware store (Postgres + PGGraph or Neo4j optional).
- Provide HTTP API to create/update nodes and edges.
- Run periodic graph maintenance tasks (deduplication, enrichment, reindexing).
- Publish events for graph changes: kg.node.created, kg.node.updated, kg.edge.created.
- Expose health, readiness, and Prometheus metrics.

Architecture overview
- Built with Python 3.11 and FastAPI for HTTP API.
- Uses SQLAlchemy + Alembic for schema migrations targeting Postgres + pgvector extension for embeddings.
- Optional graph back-end adapter interface allows Neo4j or Postgres-graph implementations.
- Uses Redis for caching and short-lived locks for ingestion concurrency control.
- Publishes events to Kafka for downstream consumers.

API contract
Base path: /api/v1/kg

- POST /api/v1/kg/nodes
  Request (application/json):
    {
      "external_id": "paper:1234",
      "type": "paper",
      "properties": {"title": "...", "authors": ["a","b"]},
      "embedding": [0.12, 0.23, ...]
    }
  Response: 201 Created
    {
      "id": "uuid",
      "external_id": "paper:1234",
      "type": "paper",
      "created_at": "2026-06-24T00:00:00Z"
    }

- GET /api/v1/kg/nodes/{id}
  Response: 200 OK -> Node resource

- POST /api/v1/kg/search
  Request: { "query_embedding": [...], "k": 10 }
  Response: 200 OK -> list of nearest nodes with distances

Health & observability
- /api/v1/health (liveness)
- /api/v1/ready (readiness: DB + Redis + Kafka)
- /metrics (Prometheus)

Environment variables
- KG_PORT (default 8081)
- KG_ENV (production|staging|development)
- KG_DATABASE_URL (postgres://...)
- KG_REDIS_URL (redis://...)
- KG_KAFKA_BROKERS
- KG_LOG_LEVEL
- KG_EMBEDDING_DIM

Database schema
- nodes (id UUID PK, external_id TEXT UNIQUE, type TEXT, properties JSONB, embedding vector, created_at, updated_at)
- edges (id UUID PK, src_uuid, dst_uuid, relation TEXT, properties JSONB, created_at)
- node_index (materialized view for search)

Events
- kg.node.created {id, external_id, type, created_at}
- kg.node.updated {id, changes, updated_at}
- kg.edge.created {id, src_id, dst_id, relation}

Operational notes
- Use pinned migrations with alembic; migrations folder contains canonical SQL used in production.
- Embeddings stored as pgvector (install extension) and indexed via ivfflat when embedding_dim > 64.
- Set up consumer groups for downstream event processing to avoid duplication.

Run locally
- Copy .env.example to .env
- Start Postgres with pgvector and Redis
- pip install -r requirements.txt
- uvicorn services.knowledge_graph_service.src.main:app --host 0.0.0.0 --port ${KG_PORT:-8081}

## Quickstart example
Below is a minimal example demonstrating how to call the vector search API and interpret the response.

Request:

curl -sS -X POST "http://localhost:8081/api/v1/kg/search" \
  -H "Content-Type: application/json" \
  -d '{"query_embedding": [0.12, 0.23, 0.34, 0.45], "k": 3}'

Example response (200 OK):

{
  "results": [
    {"id": "uuid-1", "external_id": "paper:1234", "type": "paper", "distance": 0.12, "properties": {"title": "An example paper"}},
    {"id": "uuid-2", "external_id": "paper:5678", "type": "paper", "distance": 0.35, "properties": {"title": "Related work"}},
    {"id": "uuid-3", "external_id": "paper:9012", "type": "paper", "distance": 0.78, "properties": {"title": "Distant paper"}}
  ]
}

Notes:
- The search API returns a `results` array sorted by ascending distance (lower distance = more similar).
- Distances are typically cosine or euclidean distances depending on your embedding/vector index configuration.
- If your service exposes authentication, include appropriate Authorization headers; the example assumes an open local instance for development.
