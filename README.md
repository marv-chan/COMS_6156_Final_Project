# COMS6156 Final Project
# Uniswap V2 in Vyper

This project is a reimplementation of Uniswap V2 in Vyper. The purpose of this project is to document and understand the difficulties of learning Vyper. It is also to examine the differences between Solidity and Vyper, and what the benefits and drawbacks of those differences are. 

## Structure

Deliverables: assignments

Uniswap V2 in Vyper: contracts

Tests: tests

## Usage

### Dependencies

Install vyper

```
pip install vyper
```

Install brownie


```
pip install --user pipx
pipx ensurepath
pipx install eth-brownie
```

### Run tests
```
brownie test --coverage
```