# @version ^0.3.x

from vyper.interfaces import ERC20
import UniswapV2ERC20 as UniswapV2ERC20

interface IUniswapV2Pair:
    def getReserves() -> (decimal, decimal, uint256): view

interface IUniswapV2Factory:
    def feeTo() -> address: view

implements: UniswapV2ERC20

MINIMUM_LIQUIDITY: constant(uint256) = 1000

factory: public(address)
token0: public(address)
token1: public(address)

# size of the 3 variables sums to 256 bits, it is to save gas
reserve0: decimal # suppose to be uint112
reserve1: decimal # suppose to be uint112
blockTimestampLast: uint256 # suppose to be uint32

price0CumulativeLast: public(uint256)
price1CumulativeLast: public(uint256)

# this can be done in decimal, but uniswap does it in uint256, so uint256 is kept
kLast: public(uint256) # reserve0 * reserve1, as of immediately after the most recent liquidity event

unlocked: uint256

event Mint:
    sender: indexed(address)
    amount0: uint256
    amount1: uint256

event Burn:
    sender: indexed(address)
    amount0: uint256
    amount1: uint256
    to: indexed(address)

event Swap:
    sender: indexed(address)
    amount0In: uint256
    amount1In: uint256
    amount0Out: uint256
    amount1Out: uint256
    to: indexed(address)

event Sync:
    reserve0: decimal
    reserve1: decimal


# variables for UniswapV2ERC20

name: constant(String[32]) = "Uniswap V2"
symbol: constant(String[32]) = "UNI-V2"
decimals: constant(uint8) = 18

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

DOMAIN_SEPARATOR: public(bytes32)
PERMIT_TYPEHASH: constant(bytes32) = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
nonces: public(HashMap[address, uint256])

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

### ERC20 Functions

@external
@pure
def name() -> String[32]:
    return name

@external
@pure
def symbol() -> String[32]:
    return symbol

@external
@pure
def decimals() -> uint8:
    return decimals

@internal
def _mint(_to: address, _value: uint256):
    self.totalSupply = self.totalSupply + _value
    self.balanceOf[_to] = self.balanceOf[_to] + _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@internal
def _burn(_from: address, _value: uint256):
    self.balanceOf[_from] = self.balanceOf[_from] - _value
    self.totalSupply = self.totalSupply - _value
    log Transfer(_from, ZERO_ADDRESS, _value)

@internal
def _approve(_owner: address, _spender: address, _value: uint256):
    self.allowance[_owner][_spender] = _value
    log Approval(_owner, _spender, _value)

@internal
def _transfer(_from: address, _to: address, _value: uint256):
    self.balanceOf[_from] = self.balanceOf[_from] - _value
    self.balanceOf[_to] = self.balanceOf[_to] + _value
    log Transfer(_from, _to, _value)

@external
def approve(_spender : address, _value : uint256) -> bool:
    self._approve(msg.sender, _spender, _value)
    return True

@external
def transfer(_to : address, _value : uint256) -> bool:
    self._transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    # don't need to check overflow because vyper checks for overflow
    self.allowance[_from][msg.sender] = self.allowance[_from][msg.sender] - _value
    return True

@external
@pure
def PERMIT_TYPEHASH() -> bytes32:
    return PERMIT_TYPEHASH

@external
@view
def nounces(owner: address) -> uint256:
    return self.nonces[owner]

@external
def permit(_owner: address, _spender: address, _value: uint256, _deadline: uint256, _v: uint8, _r: bytes32, _s: bytes32):
    assert _deadline >= block.timestamp
    digest: bytes32 = keccak256(
        _abi_encode(
            '\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(_abi_encode(PERMIT_TYPEHASH, _owner, _spender, _value, self.nonces[_owner], _deadline))
        )
    )
    self.nonces[_owner] = self.nonces[_owner] + 1
    # understand what this is
    recoveredAddress: address = ecrecover(digest, convert(_v, uint256), convert(_r, uint256), convert(_s, uint256))
    assert (recoveredAddress != ZERO_ADDRESS) and (recoveredAddress == _owner)
    self._approve(_owner, _spender, _value)


# https://github.com/vyperlang/vyper/issues/2326
# __init__ is not run when created with create_forwarder_to()
@external
def __init__():
    self.factory = msg.sender

@external
def initialize(_token0: address, _token1: address):
    # cannot perform assert below because create_forwarder_to 
    # does not call __init__
    # this means that anyone can duplicate this contract
    # this means more security flaw
    # assert msg.sender == self.factory
    
    # can only be initialized once
    assert self.factory == ZERO_ADDRESS # not in uniswap code

    # initialize for ERC20

    # initialize for UniswapV2Pair
    self.token0 = _token0
    self.token1 = _token1
    self.unlocked = 1
    self.factory = msg.sender # need this because __init__ is not called

@external
@view
def getReserves() -> (decimal, decimal, uint256):
    return (self.reserve0, self.reserve1, self.blockTimestampLast)

@internal
def _safeTransfer(token: address, to: address, _value: uint256):
    # TODO: uniswap v2 uses abi not used here
    # uniswap returns 2 values when transfer() is called, but only 1 is returned in Token.vy
    success: bool = ERC20(token).transfer(to, _value)
    assert success


@internal
def _update(balance0: uint256, balance1: uint256, _reserve0: decimal, _reserve1: decimal):
    # TODO: is assert required here? don't think so because of built in overflow check
    blockTimestamp: uint256 = block.timestamp
    # If the time elapsed is not zero, it means we are the first exchange transaction on this block. 
    # In that case, we need to update the cost accumulators.
    timeElapsed: uint256 = blockTimestamp - self.blockTimestampLast
    if (timeElapsed > 0) and (_reserve0 != 0.0) and (_reserve1 != 0.0):
        self.price0CumulativeLast += convert(_reserve0 / _reserve0, uint256) * timeElapsed
        self.price1CumulativeLast += convert(_reserve0 / _reserve1, uint256) * timeElapsed
    self.reserve0 = convert(balance0, decimal)
    self.reserve1 = convert(balance1, decimal)
    self.blockTimestampLast = blockTimestamp
    log Sync(self.reserve0, self.reserve1)

@internal
def _mintFee(_reserve0: decimal, _reserve1: decimal) -> bool:
    feeTo: address = IUniswapV2Factory(self.factory).feeTo()
    feeOn: bool = feeTo != ZERO_ADDRESS
    _kLast: uint256 = self.kLast
    if feeOn:
        if _kLast != 0:
            # these can be done to a greater level of accuracy with decimal
            rootK: uint256 = convert(sqrt(_reserve0 * _reserve1), uint256)
            rootKLast: uint256 = convert(sqrt(convert(_kLast, decimal)), uint256)
            if rootK > rootKLast:
                numerator: uint256 = self.totalSupply * (rootK - rootKLast)
                denominator: uint256 = rootK * 5 + rootKLast
                liquidity: uint256 = numerator / denominator
                if liquidity > 0:
                    self._mint(feeTo, liquidity)
    elif _kLast != 0:
        # no fees collected
        _kLast = 0
    return feeOn

# called when liquidity provider adds liquidity to the pool
# reserves are how much this Uniswap V2 contract owns of each token
# balances are how much the token contracts say this uniswapv2pair contract owns
# amounts are how much balances are over reserves
# the excess is what the liquidity provider deposited in and used to calulate amount of LP token 
# the liquidity provider gets back
@external
def mint(to: address) -> uint256:
    assert self.unlocked == 1
    self.unlocked = 0
    _reserve0: decimal = 0.0
    _reserve1: decimal = 0.0
    _blockTimestampLast: uint256 = 0
    (_reserve0, _reserve1, _blockTimestampLast) = IUniswapV2Pair(self).getReserves()
    balance0: uint256 = ERC20(self.token0).balanceOf(self)
    balance1: uint256 = ERC20(self.token1).balanceOf(self)
    amount0: uint256 = balance0 - convert(_reserve0, uint256)
    amount1: uint256 = balance1 - convert(_reserve1, uint256)
    feeOn: bool = self._mintFee(_reserve0, _reserve1)
    _totalSupply: uint256 = self.totalSupply
    liquidity: uint256 = 0 # amount of liquidity in the pool
    if _totalSupply == 0:
        # there is 0 supply of liquidity token
        # need to transfer MINIMUM_LIQUIDITY to ZERO_ADDRESS
        liquidity = convert(sqrt(convert(amount0 * amount1, decimal)), uint256) - MINIMUM_LIQUIDITY
        self._mint(ZERO_ADDRESS, MINIMUM_LIQUIDITY)
    else:
        liquidity = min(amount0 * _totalSupply / convert(_reserve0, uint256), amount1 * _totalSupply / convert(_reserve1, uint256))
    assert liquidity > 0
    self._mint(to, liquidity)

    self._update(balance0, balance1, _reserve0, _reserve1)
    if feeOn:
        self.kLast = convert(self.reserve0, uint256) * convert(self.reserve1, uint256)
    log Mint(msg.sender, amount0, amount1)
    self.unlocked = 1
    return 0

# burn liquidity pool token and get back underlying tokens
@external
def burn(to: address) -> (uint256, uint256):
    assert self.unlocked == 1
    self.unlocked = 0
    _reserve0: decimal = 0.0
    _reserve1: decimal = 0.0
    _blockTimestampLast: uint256 = 0
    (_reserve0, _reserve1, _blockTimestampLast) = IUniswapV2Pair(self).getReserves()
    _token0: address = self.token0
    _token1: address= self.token1
    balance0: uint256 = ERC20(_token0).balanceOf(self)
    balance1: uint256 = ERC20(_token1).balanceOf(self)
    liquidity: uint256 = self.balanceOf[self]

    feeOn: bool = self._mintFee(_reserve0, _reserve1)
    _totalSupply: uint256 = self.totalSupply
    amount0: uint256 = liquidity * balance0 / _totalSupply
    amount1: uint256 = liquidity * balance1 / _totalSupply
    assert (amount0 > 0) and (amount1 > 0)
    self._burn(self, liquidity)
    self._safeTransfer(_token0, to, amount0)
    self._safeTransfer(_token1, to, amount1)
    balance0 = ERC20(_token0).balanceOf(self)
    balance1 = ERC20(_token1).balanceOf(self)

    self._update(balance0, balance1, _reserve0, _reserve1)
    if feeOn:
        self.kLast = convert(self.reserve0, uint256) * convert(self.reserve1, uint256)
    log Mint(msg.sender, amount0, amount1)
    self.unlocked = 1
    return 0, 0

# need to send amountIn first before amountOut can be taken out
@external
def swap(amount0Out: uint256, amount1Out: uint256, to: address):
    assert self.unlocked == 1
    self.unlocked = 0

    assert amount0Out > 0 or amount1Out > 0
    _reserve0: decimal = 0.0
    _reserve1: decimal = 0.0
    _blockTimestampLast: uint256 = 0
    (_reserve0, _reserve1, _blockTimestampLast) = IUniswapV2Pair(self).getReserves()
    assert amount0Out < convert(_reserve0, uint256) and amount1Out < convert(_reserve1, uint256)

    _token0: address = self.token0
    _token1: address= self.token1
    assert to != _token0 and to!= _token1
    if amount0Out > 0:
        self._safeTransfer(_token0, to, amount0Out)
    if amount1Out > 0:
        self._safeTransfer(_token1, to, amount1Out)
    # to inform receiver of swap (no necessary)
    # if data.length > 0:
    #     IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data)
    balance0: uint256 = ERC20(_token0).balanceOf(self)
    balance1: uint256 = ERC20(_token1).balanceOf(self)
    amount0In: uint256 = 0
    amount1In: uint256 = 0
    if balance0 > convert(_reserve0, uint256) - amount0Out:
        amount0In = balance0 - (convert(_reserve0, uint256) - amount0Out)
    if balance1 > convert(_reserve1, uint256) - amount0Out:
        amount1In = balance1 - (convert(_reserve1, uint256) - amount1Out)
    assert amount0In > 0 or amount1In > 0
    balance0Adjusted: uint256 = (balance0 * 1000) - (amount0In * 3)
    balance1Adjusted: uint256 = (balance1 * 1000) - (amount1In * 3)
    # TODO convert before multiply or multipy before convert?
    assert balance0Adjusted * balance1Adjusted >= convert(_reserve0, uint256) * convert(_reserve1, uint256) * 1000 * 1000
    
    self._update(balance0, balance1, _reserve0, _reserve1)
    log Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to)
    self.unlocked = 1

@external
def skim(to: address):
    assert self.unlocked == 1
    self.unlocked = 0

    _token0: address = self.token0
    _token1: address= self.token1
    self._safeTransfer(_token0, to, ERC20(_token0).balanceOf(self) - convert(self.reserve0, uint256))
    self._safeTransfer(_token1, to, ERC20(_token1).balanceOf(self) - convert(self.reserve1, uint256))

    self.unlocked = 1

@external
def sync():
    assert self.unlocked == 1
    self.unlocked = 0

    self._update(ERC20(self.token0).balanceOf(self), ERC20(self.token1).balanceOf(self), self.reserve0, self.reserve1)

    self.unlocked = 1