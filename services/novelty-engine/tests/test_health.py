import asyncio
import math
from fastapi.testclient import TestClient
import pytest

from services.novelty_engine.src import main as novelty

client = TestClient(novelty.app)

class FakeConn:
    def __init__(self, rows=None, row=None):
        self._rows = rows or []
        self._row = row

    async def __aenter__(self):
        return self
n
    async def __aexit__(self, exc_type, exc, tb):
        return False

    async def fetchrow(self, *args, **kwargs):
        return self._row

    async def fetch(self, *args, **kwargs):
        return self._rows

class FakePool:
    def __init__(self, rows=None, row=None):
        self._rows = rows
        self._row = row

    async def acquire(self):
        return FakeConn(self._rows, self._row)

    async def close(self):
        return None


@pytest.mark.asyncio
async def test_ready_fails_when_db_unreachable(monkeypatch):
    async def fail_db():
        raise RuntimeError("db down")

    monkeypatch.setattr(novelty, 'get_db_pool', fail_db)

    resp = client.get('/api/v1/ready')
    assert resp.status_code == 503
    assert 'db down' in resp.json().get('detail', '')


def test_score_requires_input(monkeypatch):
    # Empty payload should return 400 with explicit error
    r = client.post('/api/v1/novelty/score', json={})
    assert r.status_code == 400
    assert 'document_id or embedding' in r.json()['detail']


def test_score_computes_novelty_from_neighbors(monkeypatch):
    # Prepare synthetic neighbors with distances
    rows = [
        {'id': '11111111-1111-1111-1111-111111111111', 'properties': {'title': 'A'}, 'distance': 0.2},
        {'id': '22222222-2222-2222-2222-222222222222', 'properties': {'title': 'B'}, 'distance': 0.6},
        {'id': '33333333-3333-3333-3333-333333333333', 'properties': {'title': 'C'}, 'distance': 0.9}
    ]

    fake_pool = FakePool(rows=rows, row={'embedding': [0.1, 0.2, 0.3]})

    async def get_pool():
        return fake_pool

    monkeypatch.setattr(novelty, 'get_db_pool', get_pool)

    payload = {'embedding': [0.1, 0.2, 0.3], 'k': 3}
    r = client.post('/api/v1/novelty/score', json=payload)
    assert r.status_code == 200
    data = r.json()
    # verify neighbors list structure and ordering by distance
    assert len(data['neighbors']) == 3
    assert data['neighbors'][0]['distance'] <= data['neighbors'][1]['distance']
    # compute expected novelty per service's formula
    avg = sum([row['distance'] for row in rows]) / len(rows)
    expected = 1.0 - (1.0 / (1.0 + math.exp(- (avg - 0.5))))
    assert abs(data['score'] - expected) < 1e-6


def test_score_404_for_missing_document(monkeypatch):
    # Simulate fetchrow returning None for document lookup
    fake_pool = FakePool(rows=[], row=None)

    async def get_pool():
        return fake_pool

    monkeypatch.setattr(novelty, 'get_db_pool', get_pool)

    r = client.post('/api/v1/novelty/score', json={'document_id': 'non-existent'})
    assert r.status_code == 404
    assert 'document not found' in r.json()['detail']
