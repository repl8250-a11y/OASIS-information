from fastapi import FastAPI

app = FastAPI(title="Integration Service")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}
