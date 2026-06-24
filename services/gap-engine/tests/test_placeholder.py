def test_gaps_endpoint():
    from fastapi.testclient import TestClient
    from services.gap_engine.src.main import app

    client = TestClient(app)
    r = client.get('/api/v1/gaps?topic=ai')
    assert r.status_code == 200
    data = r.json()
    assert 'topic' in data
    assert data['topic'] == 'ai'
    assert 'gaps' in data
