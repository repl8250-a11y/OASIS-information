from fastapi import FastAPI, WebSocket

app = FastAPI(title="Collaboration Service")

@app.get('/api/v1/health')
async def health():
    return {"status": "ok"}

@app.websocket('/ws/session/{session_id}')
async def session_ws(websocket: WebSocket, session_id: str):
    await websocket.accept()
    await websocket.send_text('connected')
    await websocket.close()
