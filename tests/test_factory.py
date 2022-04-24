import pytest
from brownie.network.contract import Contract
from brownie.convert import EthAddress
from brownie import UniswapV2Pair

@pytest.fixture
def pairContract(UniswapV2Pair, accounts):
	yield UniswapV2Pair.deploy({'from': accounts[0]})

@pytest.fixture
def factoryContract(UniswapV2Factory, pairContract, accounts):
	yield UniswapV2Factory.deploy(accounts[0], pairContract, {'from': accounts[0]})

def test_createPair(factoryContract, token0, token1, fn_isolation):
	tx1 = factoryContract.createPair(token0, token1)
	assert len(tx1.events) == 1
	assert tx1.events[0]['pair'] == tx1.return_value
	assert tx1.events[0]['token0'] == token0.address
	assert tx1.events[0]['token1'] == token1.address
	# pair = Contract.from_abi("UniswapV2Pair", tx1.return_value, UniswapV2Pair.abi)
	pair = UniswapV2Pair.at(tx1.return_value)
	assert pair.token0() == token0.address
	assert factoryContract.address == pair.factory()
	# to test that __init__ is not run
	# assert pair.factory() == EthAddress("0x0000000000000000000000000000000000000000")