from fastapi import FastAPI

app = FastAPI(title="Gap Engine", version="0.1.0")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.get('/api/v1/gaps')
async def gaps(topic: str):
    return {"topic": topic, "gaps": []}
