from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
from dotenv import load_dotenv

from src.config import Config
from src.api.routes import entities, relationships, queries
from src.events.event_consumer import EventConsumer

load_dotenv()

app = FastAPI(
    title="ResearchOS Knowledge Graph Service",
    version="0.1.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check
@app.get("/health")
async def health():
    return {"status": "ok", "service": "knowledge-graph-service"}

# Routes
app.include_router(entities.router, prefix="/api/entities")
app.include_router(relationships.router, prefix="/api/relationships")
app.include_router(queries.router, prefix="/api/queries")

# Event consumer startup
@app.on_event("startup")
async def startup():
    event_consumer = EventConsumer()
    await event_consumer.start()

@app.on_event("shutdown")
async def shutdown():
    event_consumer = EventConsumer()
    await event_consumer.stop()

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)
