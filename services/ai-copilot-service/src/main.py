from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional
import os
import re
import httpx
import logging
from prometheus_client import Counter, Histogram, generate_latest

logger = logging.getLogger('ai-copilot')
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="OASIS AI Copilot Service", version="1.0.0")

COPILOT_PROVIDER_URL = os.getenv('COPILOT_PROVIDER_URL')
COPILOT_PROVIDER_KEY = os.getenv('COPILOT_PROVIDER_API_KEY')
KG_SERVICE_URL = os.getenv('KG_SERVICE_URL', 'http://knowledge-graph-service:8081')

REQUESTS = Counter('oasis_copilot_requests_total', 'Total copilot requests', ['status'])
DURATION = Histogram('oasis_copilot_request_duration_seconds', 'Request duration')

EMAIL_RE = re.compile(r"[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}")
PHONE_RE = re.compile(r"\+?\d[\d\s\-()]{7,}\d")

class CopilotRequest(BaseModel):
    prompt: str = Field(..., min_length=1, max_length=8000)
    context_ids: Optional[List[str]] = None
    max_tokens: Optional[int] = 512

class CopilotResponse(BaseModel):
    response: str
    model: str
    latency_ms: int

def redact(text: str) -> str:
    # Remove emails and phone numbers
    t = EMAIL_RE.sub('[REDACTED_EMAIL]', text)
    t = PHONE_RE.sub('[REDACTED_PHONE]', t)
    return t

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.get('/api/v1/ready')
async def ready():
    # Simple readiness: provider key present
    if not COPILOT_PROVIDER_KEY:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail='LLM provider not configured')
    return {"status": "ready"}

@app.get('/metrics')
async def metrics():
    return generate_latest()

@app.post('/api/v1/copilot/query', response_model=CopilotResponse)
async def query(req: CopilotRequest):
    import time
    start = time.time()
    # Basic input validation is handled by Pydantic
    # Fetch context from KG service if provided
    context_text = ''
    if req.context_ids:
        async with httpx.AsyncClient(timeout=10.0) as client:
            parts = []
            for cid in req.context_ids:
                try:
                    r = await client.get(f"{KG_SERVICE_URL}/api/v1/kg/nodes/{cid}")
                    if r.status_code == 200:
                        body = r.json()
                        parts.append(body.get('properties', {}).get('summary', '') or '')
                except Exception as e:
                    logger.warning('kg fetch failed', exc_info=e)
            context_text = '\n'.join(parts)

    prompt = (context_text + '\n' + req.prompt) if context_text else req.prompt
    redacted_prompt = redact(prompt)

    # Call external LLM provider with provider key
    if not COPILOT_PROVIDER_URL or not COPILOT_PROVIDER_KEY:
        REQUESTS.labels(status='error').inc()
        raise HTTPException(status_code=503, detail='LLM provider not configured')

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            payload = {"prompt": redacted_prompt, "max_tokens": req.max_tokens}
            headers = {"Authorization": f"Bearer {COPILOT_PROVIDER_KEY}", "Content-Type": "application/json"}
            resp = await client.post(COPILOT_PROVIDER_URL, json=payload, headers=headers)
            if resp.status_code != 200:
                REQUESTS.labels(status='error').inc()
                raise HTTPException(status_code=502, detail='llm provider error')
            data = resp.json()
            text = data.get('text') or data.get('response') or ''
            latency = int((time.time() - start) * 1000)
            REQUESTS.labels(status='ok').inc()
            DURATION.observe(latency / 1000.0)
            return CopilotResponse(response=redact(text), model=data.get('model', 'unknown'), latency_ms=latency)
        except httpx.RequestError as e:
            logger.error('llm request failed', exc_info=e)
            REQUESTS.labels(status='error').inc()
            raise HTTPException(status_code=502, detail='llm provider request failed')

