import json
import os


def test_discovery_migration_contains_constraints():
    path = os.path.join(os.path.dirname(__file__), '..', 'migrations', '001_init.sql')
    assert os.path.exists(path), 'migration file missing'
    with open(path, 'r') as f:
        contents = f.read().lower()
    # Ensure primary key, foreign key patterns and uuid extension present
    assert 'create extension if not exists "uuid-ossp"'.lower() in contents
    assert 'create table if not exists sources' in contents
    assert 'id uuid primary key' in contents
    # ensure created_at timestamp present
    assert 'created_at timestamptz' in contents


def test_export_migration_presence_and_columns():
    path = os.path.join(os.path.dirname(__file__), '..', '..', 'export-service', 'migrations', '001_init.sql')
    assert os.path.exists(path), 'export migration missing'
    with open(path, 'r') as f:
        sql = f.read().lower()
    assert 'create table if not exists export_jobs' in sql
    assert 'status text' in sql
    assert 'artifact_url text' in sql

