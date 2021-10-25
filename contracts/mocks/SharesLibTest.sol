// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/SharesLibrary.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract SharesLibTest {
    
    using SafeMathUpgradeable for uint256;
    using SharesLibrary for SharesLibrary.Data;
    
    SharesLibrary.Data t;
    
    uint256 interval;
    uint256 duration;
    
    constructor(uint256 interval_, uint256 duration_) {
        interval = interval_;
        duration = duration_;
        t.setInterval(interval_);
    }
    
    function push(uint256 value) public {
        uint256 index = getCurrentInterval();
        t.insert(value, index, index.mul(duration));
    }
    
    function getShares(uint256 index) public view returns(uint256) {
        return t.getActiveShares(index);
    }
    
    function justInsertKey(uint256 index) public {
        t.justInsertKey(index);
    }
    function getLessIndex(uint256 index) public view returns(uint256) {
        return t.getLessIndex(index);
    }
    
    function getPrev(uint256 index) public view returns(uint256) {
        return t.getPrev(index);
    }
    function getNext(uint256 index) public view returns(uint256) {
        return t.getNext(index);
    }
    function getExists(uint256 tsIndex) public view returns(bool) {
        return t.getExists(tsIndex);
    } 
    function getRoot() public view returns(uint256) {
        return t.getRoot();
    }
    function getNode(uint256 tsIndex) public view returns(uint256,uint256,uint256,uint256,bool) {
        return t.getNode(tsIndex);
    }
   
    function getCurrentInterval() internal view returns(uint256) {
        return (block.timestamp).div(interval).mul(interval);
    }
}