def test_paper_package_json_exists():
    import json
    import os
    path = os.path.join(os.path.dirname(__file__), '..', 'package.json')
    assert os.path.exists(path)
    with open(path, 'r') as f:
        pkg = json.load(f)
    assert 'scripts' in pkg
    assert 'build' in pkg['scripts'] or 'start' in pkg['scripts']
