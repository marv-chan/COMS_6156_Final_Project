import pytest
from brownie.convert import EthAddress

@pytest.fixture
def pairContract(UniswapV2Pair, accounts):
    yield UniswapV2Pair.deploy({'from': accounts[0]})

def test_init(pairContract, accounts):
    # __init__ is called if contract is created by user
    assert pairContract.factory() == accounts[0]
