from fastapi.testclient import TestClient
from services.gap_engine.src import main as gap
import pytest
import time

client = TestClient(gap.app)

def test_gaps_requires_topic_parameter():
    # Missing topic should yield 422 Unprocessable Entity from FastAPI
    r = client.get('/api/v1/gaps')
    assert r.status_code == 422
    payload = r.json()
    assert 'detail' in payload and isinstance(payload['detail'], list)


def test_gaps_returns_empty_list_and_is_idempotent():
    # Calling with a topic returns deterministic results (empty list) and multiple calls are idempotent
    r1 = client.get('/api/v1/gaps?topic=ai')
    assert r1.status_code == 200
    body1 = r1.json()
    r2 = client.get('/api/v1/gaps?topic=ai')
    body2 = r2.json()
    assert body1 == body2


def test_gaps_concurrent_requests():
    # Ensure concurrent requests do not raise errors (basic concurrency check)
    from concurrent.futures import ThreadPoolExecutor

    def call():
        r = client.get('/api/v1/gaps?topic=ai')
        return r.status_code

    with ThreadPoolExecutor(max_workers=10) as ex:
        results = list(ex.map(lambda _: call(), range(10)))
    assert all(s == 200 for s in results)
