# COMS6156 Final Project
# Uniswap V2 in Vyper

This project is a reimplementation of Uniswap V2 in Vyper. The purpose of this project is to document and understand the difficulties of learning Vyper. It is also to examine the differences between Solidity and Vyper, and what the benefits and drawbacks of those differences are. Results can be found in assignments/Final Project.pdf

## Structure

Deliverables: assignments (Initial project proposal is not included because a brand new project was proposed in the revised proposal)

Uniswap V2 in Vyper: contracts

Tests for Uniswap V2 in Vyper: tests

## Usage

### Dependencies

Install vyper

```
pip install vyper
```

More info can be found at https://vyper.readthedocs.io/en/stable/installing-vyper.html

Install brownie


```
pip install --user pipx
pipx ensurepath
pipx install eth-brownie
```

More info can be found at https://eth-brownie.readthedocs.io/en/stable/install.html

### Run tests
```
brownie test --coverage
```
