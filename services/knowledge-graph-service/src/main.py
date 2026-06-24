from fastapi import FastAPI
from .routes import router
from .db import init_db

app = FastAPI(title="OASIS Knowledge Graph Service", version="0.1.0")

@app.on_event("startup")
async def startup():
    await init_db()

app.include_router(router, prefix="/api/v1/kg")

@app.get("/api/v1/health")
async def health():
    return {"status": "ok"}

@app.get("/api/v1/ready")
async def ready():
    # TODO: implement readiness checks (DB/Redis/Kafka)
    return {"status": "ready"}
