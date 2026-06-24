import os
import json


def test_paper_migration_defines_embedding_and_constraints():
    path = os.path.join(os.path.dirname(__file__), '..', 'migrations', '001_create_papers.sql')
    assert os.path.exists(path), 'paper migration missing'
    with open(path, 'r') as f:
        sql = f.read().lower()
    assert 'create extension if not exists "uuid-ossp"'.lower() in sql
    assert 'create table if not exists papers' in sql
    assert 'embedding vector' in sql
    assert 'index if not exists idx_papers_title' in sql

