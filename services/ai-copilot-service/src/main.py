from fastapi import FastAPI

app = FastAPI(title="AI Copilot Service", version="0.1.0")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.post('/api/v1/copilot/query')
async def query(payload: dict):
    # In production: call LLM provider, apply filters, return response
    return {"response": "placeholder"}
