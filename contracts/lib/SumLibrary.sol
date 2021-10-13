// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library SumLibrary {
    
    using SafeMathUpgradeable for uint256;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    
    struct Data {
        mapping (uint256 => uint256) sum;
        BokkyPooBahsRedBlackTreeLibrary.Tree list;
    }

    // add(value) {
    //     var now = now();
    //     if (_times[_times.length-1] < now) {
    //         _times.push(now);
    //         _values[now] = value;
    //     } else {
    //         _values[now] += value;
    //     }
    // }

    function addSum(Data storage self, uint256 index, uint256 value) internal {
        if (self.list.last() < index) {
            self.sum[index] = value;
        } else {
            self.sum[index] = self.sum[index].add(value);
        }
        insertIfNotExist(self, index);
    }
    function add(Data storage self, uint256 index, uint256 value) internal {
        self.sum[index] = value;
        insertIfNotExist(self, index);
    }
    // get(index) {
    //     if (_values[index]) {
    //         return _values[index];
    //     }
    //     // otherwise index isn't in the mapping
    //     // do binary search here to find immediately previous _sum[index]
    //     return value; // of sum at that index
    // }
    function get(Data storage self, uint256 index) internal view returns(uint256) {
        if (self.list.exists(index)) {
            return self.sum[index];
        } else {
            uint256 i = self.list.last();
            while (i > index) {
                
                i = self.list.prev(i);
            }
            if (i != 0) {
                return self.sum[i];
            }
            return 0;
        }
    }
    
    function insertIfNotExist(Data storage self, uint256 index) private {
        if (!self.list.exists(index)) {
            self.list.insert(index);
        } 
    }
    
}

 
contract T  {
    
	using SafeMathUpgradeable for uint256;
	using SumLibrary for SumLibrary.Data;
	
	SumLibrary.Data q;
	
    function _now(uint256 interval) internal view returns(uint256) {
        return (block.timestamp).div(interval).mul(interval);
    }

	
	function get(uint256 interval) public view returns(uint256) {
	    return q.get(_now(interval));
	}
	function addSum(uint256 interval, uint256 w) public  {
	    q.addSum(interval,w);
	}
	
}