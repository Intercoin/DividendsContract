// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHookCaller {
    function executeTransfer(address from, address to, uint256 value) external;
}