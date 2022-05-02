# @version ^0.3.x

interface IUniswapV2Pair:
    def initialize(_token0: address, _token1: address): nonpayable

feeTo: public(address)
feeToSetter: public(address)
getPair: public(HashMap[address, HashMap[address, address]])
numberOfPairs: public(uint256)
masterCopy: public(address)

event PairCreated:
    token0: indexed(address)
    token1: indexed(address)
    pair: address

# not possible because arrays are bounded in vyper
# use numberOfPairs instead
# @external
# @view
# def allPairsLength():
# 	pass

@external
def __init__(_feeToSetter: address, _masterCopy: address):
    self.feeToSetter = _feeToSetter
    self.masterCopy = _masterCopy

@external
def createPair(tokenA: address, tokenB: address) -> address:
    assert tokenA != tokenB, "IDENTICAL_ADDRESSES"
    # need to convert first. cannot directly compare address in vyper
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    tokenAInt: uint256 = convert(tokenA, uint256)
    tokenBInt: uint256 = convert(tokenB, uint256)
    # no ternary operator in vyper
    if tokenAInt < tokenBInt:
        token0 = tokenA
        token1 = tokenB
    else:
        token0 = tokenB
        token1 = tokenA
    assert token0 != ZERO_ADDRESS, "ZERO_ADDRESS"
    assert self.getPair[token0][token1] == ZERO_ADDRESS, "PAIR_EXISTS"
    newPairAddr: address = create_forwarder_to(self.masterCopy)
    IUniswapV2Pair(newPairAddr).initialize(token0, token1)
    self.getPair[token0][token1] = newPairAddr
    self.getPair[token1][token0] = newPairAddr
    self.numberOfPairs += 1
    log PairCreated(token0, token1, newPairAddr)
    return newPairAddr

@external
def setFeeTo(_feeTo: address):
    assert msg.sender == self.feeToSetter
    self.feeTo = _feeTo

@external
def setFeeToSetter(_feeToSetter: address):
    assert msg.sender == self.feeToSetter
    self.feeToSetter = _feeToSetter