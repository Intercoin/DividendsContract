// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDividends {
    function initialize(string memory, string memory, uint256, address) external;
    function stake(address, uint256) external;
    function claim() external;
    function redeem() external;
    function cleanSRC() external;
    
    // must be the same as in transfer rules
    function setSRC(address src20) external returns (bool);
    
}