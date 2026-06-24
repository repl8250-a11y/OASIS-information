from fastapi.testclient import TestClient
from services.knowledge_graph_service.src.main import app

client = TestClient(app)

def test_health():
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
