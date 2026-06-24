from fastapi import FastAPI

app = FastAPI(title="Novelty Engine", version="0.1.0")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.post('/api/v1/novelty/score')
async def score(payload: dict):
    # placeholder scoring logic
    return {"score": 0.0}
