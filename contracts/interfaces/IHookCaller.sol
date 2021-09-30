// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHookCaller {
    function executeTransfer(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) external;
}