// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDividendsContract {
    //                          name,         symbol, defaultOperators, interval, duration,multiplier, token
    function initialize(string memory, string memory, address[] memory, uint256, uint256, uint256, address) external;
    function stake(address, uint256) external;
    function claim() external;
    function redeem() external;
    
}
