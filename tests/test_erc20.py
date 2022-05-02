from termios import VTDLY
import pytest
from brownie.network.contract import Contract
from brownie.convert import EthAddress
from brownie import UniswapV2ERC20

# tests are independent of each other
def test_transfer1(token0, accounts):
    token0.transfer(accounts[1], 10000, {'from': accounts[0]})
    assert token0.balanceOf(accounts[1]) == 10000

# tests are independent of each other
def test_transfer2(token0, accounts):
    token0.transfer(accounts[1], 10000, {'from': accounts[0]})
    assert token0.balanceOf(accounts[1]) == 10000