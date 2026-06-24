from fastapi import FastAPI

app = FastAPI(title="Analytics Service")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.get('/api/v1/analytics/metrics')
async def metrics():
    return {"metrics": []}
