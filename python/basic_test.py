def test_one():
    assert 2 + 2 == 4

def test_nonstandard_module():
    import numpy as np
    assert np.linspace(1,2).shape == (50,)
