import os
from pytest import mark

def test_one():
    assert 2 + 2 == 4

def test_nonstandard_module():
    import numpy as np
    assert np.linspace(1,2).shape == (50,)

@mark.skipif(os.getenv('GITHUB_ACTIONS') != 'true',
             reason = 'Not running on GHA')
def test_version():
    import sys
    vi = sys.version_info
    found = f'python{vi.major}{vi.minor}'
    expected = os.getenv('EXPECTED_PY')
    assert(found == expected)
