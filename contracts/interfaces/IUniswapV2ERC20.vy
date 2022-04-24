# @version ^0.3.x

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

# name: public(String[32])
# symbol: public(String[32])
# decimals: public(uint8)

# balanceOf: public(HashMap[address, uint256])
# allowance: public(HashMap[address, HashMap[address, uint256]])
# totalSupply: public(uint256)

# DOMAIN_SEPARATOR: public(bytes32)
# PERMIT_TYPEHASH: constant(bytes32) = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9

@external
@pure
def name() -> String[32]:
    return ""

@external
@pure
def symbol() -> String[32]:
    return ""

@external
@pure
def decimals() -> uint8:
    return 0

@external
@view
def totalSupply() -> uint256:
    return 0

@external
@view
def balanceOf(owner: address) -> uint256:
    return 0

@external
@view
def allowance(owner: address, spender: address) -> uint256:
    return 0

@external
def approve(_spender : address, _value : uint256) -> bool:
    return True

@external
def transfer(_to : address, _value : uint256) -> bool:
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    return True

@external
@view
def DOMAIN_SEPARATOR() -> bytes32:
    return EMPTY_BYTES32

@external
@pure
def PERMIT_TYPEHASH() -> bytes32:
    return EMPTY_BYTES32

@external
@view
def nounces(owner: address) -> uint256:
    return 0

@external
def permit(_owner: address, _spender: address, _value: uint256, _deadline: uint256, _v: uint8, _r: bytes32, _s: bytes32):
    pass