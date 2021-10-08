// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDividendsContract {
    //                          name,         symbol, defaultOperators, interval, duration,multiplier, token, whitelist
    function initialize(string memory, string memory, address[] memory, uint256, uint256, uint256, address, address[] memory) external;
    function getInterval() external view returns(uint256);
    function disburse(address, uint256) external;
    // function stake(address, uint256) external;
    // function claim() external;
    // function redeem() external;
    
}
