import pytest
from brownie import Token, accounts

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass

@pytest.fixture(scope="module")
def token0(Token, accounts):
    return Token.deploy("Test Token0", "TST0", 18, 1e21, {'from': accounts[0]})

@pytest.fixture(scope="module")
def token1(Token, accounts):
    return Token.deploy("Test Token1", "TST1", 18, 1e21, {'from': accounts[0]})

# @pytest.fixture(scope="module")
# def pairContract(UniswapV2Pair, accounts):
#     print(accounts[0])
#     yield UniswapV2Pair.deploy({'from': accounts[0]})

# @pytest.fixture(scope="module")
# def factoryContract(UniswapV2Factory, pairContract, accounts):
#     yield UniswapV2Factory.deploy(accounts[0], pairContract, {'from': accounts[0]})