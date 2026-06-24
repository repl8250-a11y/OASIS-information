def test_discovery_migration_present():
    import os
    path = os.path.join(os.path.dirname(__file__), '..', 'migrations', '001_init.sql')
    assert os.path.exists(path), 'migration file missing'
    with open(path, 'r') as f:
        contents = f.read()
    assert 'CREATE TABLE' in contents.upper()
