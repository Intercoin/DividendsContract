// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library SumLibrary {
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using SafeMathUpgradeable for uint256;
    
    struct Data {
        mapping (uint256 => uint256) sum;
        BokkyPooBahsRedBlackTreeLibrary.Tree list;
    }

    uint256 private constant INTERVAL = 604800; //// * interval: WEEK by default

    function _now() private view returns(uint256) {
        return (block.timestamp / INTERVAL) * INTERVAL;
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

    function addSum(Data storage self, uint256 value) internal {
        uint256 timeNow = _now();
        if (self.list.last() < timeNow) {
            self.sum[timeNow] = value;
        } else {
            self.sum[timeNow] = self.sum[timeNow].add(value);
        }
    }
    function add(Data storage self, uint256 value) internal {
        uint256 timeNow = _now();
        self.sum[timeNow] = value;
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

}