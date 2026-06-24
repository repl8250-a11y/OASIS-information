from fastapi import FastAPI

app = FastAPI(title="User Service")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.get('/api/v1/users/{user_id}')
async def get_user(user_id: str):
    return {"id": user_id, "name": "Demo User"}
