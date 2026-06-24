from fastapi.testclient import TestClient
from services.analytics_service.src import main as analytics

client = TestClient(analytics.app)


def test_analytics_metrics_endpoint_contract():
    r = client.get('/api/v1/analytics/metrics')
    assert r.status_code == 200
    data = r.json()
    # the analytics service returns a JSON object with 'metrics' key for programmatic scraping
    assert isinstance(data, dict)
    assert 'metrics' in data
    assert isinstance(data['metrics'], list)
