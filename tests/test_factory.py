import pytest
from brownie.network.contract import Contract
from brownie.convert import EthAddress
from brownie import reverts
from brownie import UniswapV2Pair

@pytest.fixture
def pairContract(UniswapV2Pair, accounts):
    yield UniswapV2Pair.deploy({'from': accounts[0]})

@pytest.fixture
def factoryContract(UniswapV2Factory, pairContract, accounts):
    yield UniswapV2Factory.deploy(accounts[0], pairContract, {'from': accounts[0]})

def test_createPair(factoryContract, token0, token1, accounts, fn_isolation):
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

def test_createPair_zeroAddressFail(factoryContract, token0, token1, accounts):
    with reverts("ZERO_ADDRESS"):
        factoryContract.createPair(EthAddress("0x0000000000000000000000000000000000000000"), token1)

def test_createPair_duplicateFail(factoryContract, token0, token1, accounts):
    factoryContract.createPair(token0, token1)
    with reverts("PAIR_EXISTS"):
        factoryContract.createPair(token1, token0)

def test_createPair_identicalFail(factoryContract, token0, token1, accounts):
    with reverts("IDENTICAL_ADDRESSES"):
        factoryContract.createPair(token0, token0)

def test_setter(factoryContract, accounts):
    factoryContract.setFeeToSetter(accounts[1], {'from': accounts[0]})
    factoryContract.setFeeTo(accounts[0], {'from': accounts[1]})
    assert factoryContract.feeTo() == accounts[0]
    assert factoryContract.feeToSetter() == accounts[1]

def test_setFeeToSetter_fail(factoryContract, accounts):
    with reverts():
        factoryContract.setFeeToSetter(accounts[1], {'from': accounts[1]})

def test_feeTo_fail(factoryContract, accounts):
    with reverts():
        factoryContract.setFeeTo(accounts[1], {'from': accounts[1]})
