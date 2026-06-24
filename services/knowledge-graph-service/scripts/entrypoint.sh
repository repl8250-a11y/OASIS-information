#!/usr/bin/env bash
set -euo pipefail

if [ -n "${KG_DATABASE_URL:-}" ]; then
  echo "Running migrations against ${KG_DATABASE_URL}"
  # assume alembic or SQL migration tooling is present; keep as no-op otherwise
fi

exec uvicorn services.knowledge_graph_service.src.main:app --host 0.0.0.0 --port ${KG_PORT:-8081}
