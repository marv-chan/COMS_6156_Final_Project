# COMS6156 Final Project
# Uniswap V2 in Vyper

This project is a reimplementation of Uniswap V2 Core contracts in Vyper. The purpose of this project is to document and understand the difficulties of learning Vyper. It is also to examine the differences between Solidity and Vyper, and what the benefits and drawbacks of those differences are. Results can be found in assignments/Final Project.pdf

## Structure

Deliverables: assignments folder (Initial project proposal is not included because a brand new project was proposed in the revised proposal)

Uniswap V2 in Vyper: contracts folder

Tests for Uniswap V2 in Vyper: tests folder

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

## References
1.	Vyper Documentation: https://vyper.readthedocs.io 
2.	Vyper GitHub Repo: https://github.com/vyperlang/vyper
3.	Solidity Documentation: https://docs.soliditylang.org
4.	Solidty – Vyper Cheatsheet: https://reference.auditless.com/cheatsheet/
5.	Brownie Documentation: https://eth-brownie.readthedocs.io
6.	Uniswap V2 Core Contracts: https://github.com/Uniswap/v2-core
7.	Ethereum Website: https://ethereum.org
8.	Remix IDE: https://remix.ethereum.org
9.	Vyper tutorial: https://bowtiedisland.com/vyper-for-beginners-introduction/