import os
from fastapi.testclient import TestClient
from services.export_service.src import main as export

client = TestClient(export.app)


def test_export_health_and_job_schema_present():
    r = client.get('/api/v1/health')
    assert r.status_code == 200
    assert r.json()['status'] == 'ok'

    # ensure migration file present and job schema includes status and artifact_url
    path = os.path.join(os.path.dirname(__file__), '..', 'migrations', '001_init.sql')
    assert os.path.exists(path)
    with open(path, 'r') as f:
        sql = f.read().lower()
    assert 'export_jobs' in sql
    assert 'artifact_url' in sql
