# AI Copilot Service

The AI Copilot service provides centralized LLM orchestration, prompt templating, and safety filters for assistant features across the platform.

Responsibilities
- Manage calls to external LLM providers with rate-limiting and request shaping.
- Apply moderation and safety checks.
- Provide a context-aware assistant API for the frontend and other services.
- Log prompts and responses for observability (PII redaction enforced).

Architecture
- Python FastAPI service with worker pool for long-running requests.
- Integrates with vector DBs and knowledge-graph for contextual grounding.

API
- POST /api/v1/copilot/query { prompt, context_ids }

Environment
- COPILOT_PORT=8086
- COPILOT_LLM_PROVIDER_API_KEY

Run locally
- pip install -r requirements.txt
- uvicorn services/ai-copilot-service.src.main:app --port ${COPILOT_PORT:-8086}
