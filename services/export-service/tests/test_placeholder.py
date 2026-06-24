def test_export_health():
    from fastapi.testclient import TestClient
    from services.export_service.src.main import app

    client = TestClient(app)
    r = client.get('/api/v1/health')
    assert r.status_code == 200
    assert r.json()['status'] == 'ok'
