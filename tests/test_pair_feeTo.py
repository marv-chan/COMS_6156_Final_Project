import pytest
from brownie.convert import EthAddress

@pytest.fixture
def masterPairContract(UniswapV2Pair, accounts):
    yield UniswapV2Pair.deploy({'from': accounts[0]})


@pytest.fixture
def factoryContract(UniswapV2Factory, masterPairContract, accounts):
    factory = UniswapV2Factory.deploy(accounts[0], masterPairContract, {'from': accounts[0]})
    factory.setFeeTo(accounts[0], {'from': accounts[0]})
    yield factory


@pytest.fixture
def newPairContract(UniswapV2Pair, factoryContract, token1, token0, accounts):
    yield UniswapV2Pair.at(factoryContract.createPair(token0, token1).return_value)


@pytest.fixture
def mintedPairContract(UniswapV2Pair, factoryContract, token1, token0, accounts):
    token0.transfer(accounts[1], 20000, {'from': accounts[0]})
    token1.transfer(accounts[1], 20000, {'from': accounts[0]})
    pairAddr = factoryContract.createPair(token0, token1).return_value
    token0.transfer(pairAddr, 10000, {'from': accounts[1]})
    token1.transfer(pairAddr, 10000, {'from': accounts[1]})
    pair = UniswapV2Pair.at(pairAddr)
    pair.mint(accounts[1], {'from': accounts[1]})
    yield pair


def test_init(UniswapV2Pair, accounts):
    # __init__ is only called if contract is created by user
    pair = UniswapV2Pair.deploy({'from': accounts[0]})
    assert pair.factory() == accounts[0]


def test_mint(newPairContract, token0, token1, accounts):
    # fund pair contract
    token0.transfer(newPairContract, 10000, {'from': accounts[0]})
    token1.transfer(newPairContract, 10000, {'from': accounts[0]})
    tx = newPairContract.mint(accounts[0], {'from': accounts[0]})
    assert len(tx.events) == 4
    # pair token has never been funded before, so send 1000 to 0x0
    assert tx.events[0]['receiver'] == EthAddress("0x0000000000000000000000000000000000000000")
    assert tx.events[0]['value'] == 1000
    # create more supply for liquidity provider
    assert tx.events[1]['receiver'] == accounts[0]
    assert tx.events[1]['value'] == 9000
    # Sync in _update()
    assert tx.events[2]['reserve0'] == 10000 
    assert tx.events[2]['reserve1'] == 10000
    # Mint in mint()
    assert tx.events[3]['sender'] == accounts[0]
    assert tx.events[3]['amount0'] == 10000
    assert tx.events[3]['amount1'] == 10000


def test_mint2(newPairContract, token0, token1, accounts):
    # fund pair contract
    token0.transfer(newPairContract, 10000, {'from': accounts[0]})
    token1.transfer(newPairContract, 10000, {'from': accounts[0]})
    newPairContract.mint(accounts[0], {'from': accounts[0]})
    token0.transfer(newPairContract, 10000, {'from': accounts[0]})
    token1.transfer(newPairContract, 10000, {'from': accounts[0]})
    tx = newPairContract.mint(accounts[0], {'from': accounts[0]})
    # create more supply for liquidity provider
    assert tx.events[0]['value'] == 10000
    # Sync in _update()
    assert tx.events[1]['reserve0'] == 20000 
    assert tx.events[1]['reserve1'] == 20000
    # Mint in mint()
    assert tx.events[2]['amount0'] == 10000
    assert tx.events[2]['amount1'] == 10000



def test_burn(mintedPairContract, token0, token1, accounts):
    mintedPairContract.transfer(mintedPairContract, 5000, {'from': accounts[1]})
    tx = mintedPairContract.burn(accounts[1], {'from': accounts[1]})
    assert len(tx.events) == 5
    # transfer burn token to address 0x0 called in _burn()
    assert tx.events[0]['receiver'] == EthAddress("0x0000000000000000000000000000000000000000")
    assert tx.events[0]['value'] == 5000
    # transfer token0 to caller
    assert tx.events[1]['receiver'] == accounts[1]
    assert tx.events[1]['value'] == 5000
    # transfer token1 to caller
    assert tx.events[2]['receiver'] == accounts[1]
    assert tx.events[2]['value'] == 5000
    # Sync in _update()
    assert tx.events[3]['reserve0'] == 5000 
    assert tx.events[3]['reserve1'] == 5000
    # Mint
    assert tx.events[4]['sender'] == accounts[1]
    assert tx.events[4]['amount0'] == 5000
    assert tx.events[4]['amount1'] == 5000


def test_mintedPairContractVars(mintedPairContract, token0, token1):
    assert token0.balanceOf(mintedPairContract.address) == 10000
    assert token1.balanceOf(mintedPairContract.address) == 10000
    reserve0, reserve1, timestamp = mintedPairContract.getReserves()
    assert reserve0 == 10000
    assert reserve1 == 10000


def test_swap(mintedPairContract, token0, token1, accounts):
    token1.transfer(mintedPairContract, 1000, {'from': accounts[1]})
    tx = mintedPairContract.swap(500, 0, accounts[1], {'from': accounts[1]})
    assert len(tx.events) == 3
    # send withdraw to swapper
    assert tx.events[0]['receiver'] == accounts[1]
    assert tx.events[0]['value'] == 500
    # Sync in _update()
    assert tx.events[1]['reserve0'] == 9500 
    assert tx.events[1]['reserve1'] == 11000
    # Swap
    assert tx.events[2]['amount0In'] == 0
    assert tx.events[2]['amount1In'] == 1000
    assert tx.events[2]['amount0Out'] == 500
    assert tx.events[2]['amount1Out'] == 0
