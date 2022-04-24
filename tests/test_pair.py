import pytest

@pytest.fixture
def pairContract(UniswapV2Pair, accounts):
	yield UniswapV2Pair.deploy({'from': accounts[0]})

def test_initialize(pairContract, accounts):
	assert pairContract.factory() == accounts[0]