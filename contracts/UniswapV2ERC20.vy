# @version ^0.3.x

from contracts.interfaces import IUniswapV2ERC20

implements: IUniswapV2ERC20

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

@external
def __init__():
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            keccak256('EIP712Domain(name: String[32],version: String[32],chainId: uint256,verifyingContract: address)'),
            keccak256(name),
            keccak256("1"),
            chain.id,
            self
        )
    )

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
    recoveredAddress: address = ecrecover(digest, convert(_v, uint256), convert(_r, uint256), convert(_s, uint256))
    assert (recoveredAddress != ZERO_ADDRESS) and (recoveredAddress == _owner)
    self._approve(_owner, _spender, _value)
