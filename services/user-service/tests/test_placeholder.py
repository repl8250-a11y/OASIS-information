def test_user_service_get():
    from fastapi.testclient import TestClient
    from services.user_service.src.main import app

    client = TestClient(app)
    r = client.get('/api/v1/users/00000000-0000-0000-0000-000000000000')
    assert r.status_code == 200
    data = r.json()
    assert 'id' in data
    assert 'name' in data
