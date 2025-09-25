// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETX is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;

    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}