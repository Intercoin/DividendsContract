// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHook {
    function doSetup() external;
    function clearSetup() external;
    function doTransfer(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) external;
}