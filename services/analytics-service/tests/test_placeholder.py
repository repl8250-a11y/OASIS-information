def test_analytics_metrics():
    from fastapi.testclient import TestClient
    from services.analytics_service.src.main import app

    client = TestClient(app)
    r = client.get('/api/v1/analytics/metrics')
    assert r.status_code == 200
    data = r.json()
    assert 'metrics' in data
