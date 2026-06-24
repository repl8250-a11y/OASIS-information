from typing import List, Optional
import os
import asyncio
import logging
import math

from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel, conlist, constr

import asyncpg
import aioredis
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Production-grade novelty engine service

SERVICE_NAME = "novelty-engine"
DB_DSN = os.getenv("NOVELTY_DATABASE_URL")
REDIS_URL = os.getenv("NOVELTY_REDIS_URL")
K = int(os.getenv("NOVELTY_DEFAULT_K", "10"))

logger = logging.getLogger(SERVICE_NAME)
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="OASIS Novelty Engine", version="1.0.0")

# Metrics
REQUESTS = Counter('oasis_novelty_requests_total', 'Total requests', ['endpoint', 'method', 'status'])
DURATION = Histogram('oasis_novelty_request_duration_seconds', 'Request duration', ['endpoint', 'method'])

# DB and cache pools
_db_pool: Optional[asyncpg.pool.Pool] = None
_redis: Optional[aioredis.Redis] = None

class ScoreRequest(BaseModel):
    document_id: Optional[constr(strip_whitespace=True, min_length=1)] = None
    embedding: Optional[List[float]] = None
    k: Optional[int] = K

class ScoreResponse(BaseModel):
    document_id: Optional[str]
    score: float
    neighbors: List[dict]

async def get_db_pool():
    global _db_pool
    if _db_pool is None:
        if not DB_DSN:
            raise RuntimeError("NOVELTY_DATABASE_URL not configured")
        _db_pool = await asyncpg.create_pool(dsn=DB_DSN, min_size=1, max_size=10)
    return _db_pool

async def get_redis():
    global _redis
    if _redis is None:
        if not REDIS_URL:
            raise RuntimeError("NOVELTY_REDIS_URL not configured")
        _redis = await aioredis.from_url(REDIS_URL)
    return _redis

@app.on_event("startup")
async def startup_event():
    await get_db_pool()
    await get_redis()
    logger.info("novelty-engine started")

@app.on_event("shutdown")
async def shutdown_event():
    global _db_pool, _redis
    if _db_pool:
        await _db_pool.close()
    if _redis:
        await _redis.close()
    logger.info("novelty-engine stopped")

@app.get('/metrics')
async def metrics():
    return generate_latest()

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.get('/api/v1/ready')
async def ready():
    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            await conn.execute('SELECT 1')
        r = await get_redis()
        await r.ping()
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(e))
    return {"status": "ready"}

@app.post('/api/v1/novelty/score', response_model=ScoreResponse)
async def score(req: ScoreRequest):
    start = asyncio.get_event_loop().time()
    endpoint = '/api/v1/novelty/score'
    try:
        if req.embedding is None and req.document_id is None:
            raise HTTPException(status_code=400, detail="document_id or embedding must be provided")

        pool = await get_db_pool()
        # If document_id provided, load its embedding
        embedding = req.embedding
        if req.document_id is not None and embedding is None:
            async with pool.acquire() as conn:
                row = await conn.fetchrow('SELECT embedding FROM nodes WHERE id = $1', req.document_id)
                if not row:
                    raise HTTPException(status_code=404, detail="document not found")
                embedding = row['embedding']

        if embedding is None:
            raise HTTPException(status_code=400, detail="embedding not available")

        k = min(req.k or K, 100)
        # Use pgvector operator <-> for distance. Ensure pgvector extension and nodes.embedding exists.
        async with pool.acquire() as conn:
            rows = await conn.fetch(f"SELECT id, properties, embedding <-> $1 AS distance FROM nodes ORDER BY distance ASC LIMIT {k}", embedding)
            neighbors = []
            for r in rows:
                neighbors.append({
                    'id': str(r['id']),
                    'properties': r['properties'],
                    'distance': float(r['distance'])
                })

        # Simple novelty heuristic: average distance to k nearest neighbors
        if len(neighbors) == 0:
            novelty = 1.0
        else:
            avg = sum(n['distance'] for n in neighbors) / len(neighbors)
            # Normalize using sigmoid for bounded score [0,1]
            novelty = 1.0 - (1.0 / (1.0 + math.exp(- (avg - 0.5))))

        return ScoreResponse(document_id=req.document_id, score=novelty, neighbors=neighbors)
    finally:
        elapsed = asyncio.get_event_loop().time() - start
        REQUESTS.labels(endpoint=endpoint, method='POST', status='200').inc()
        DURATION.labels(endpoint=endpoint, method='POST').observe(elapsed)

