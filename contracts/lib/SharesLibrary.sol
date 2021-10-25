// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library SharesLibrary {
    
    using SafeMathUpgradeable for uint256;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    
    struct Item {
        uint256 started;
        uint256 ended;
        uint256 active; // active is a total of verall started and ended it each backet
        //bool exists;
    }
    struct Data {
        mapping (uint256 => Item) items;
        uint256 interval;
        BokkyPooBahsRedBlackTreeLibrary.Tree list;
        uint256 lastSyncIndex;
    }
    
    
    function setInterval(Data storage self, uint256 value) internal {
        self.interval = value;
    }
    
    function insert(Data storage self, uint256 value, uint256 index, uint256 duration) internal {
        sync(self);
        
        if (!self.list.exists(index)) {
            self.list.insert(index);
        }
        self.items[index].started = self.items[index].started.add(value);
        self.items[index].active = self.items[index].active.add(value);
        
        uint256 indexEnded = index.add(duration);
        if (!self.list.exists(indexEnded)) {
            self.list.insert(indexEnded);
        }
        
        self.items[indexEnded].ended = self.items[indexEnded].ended.add(value);
    }
    
    function getActiveShares(Data storage self, uint256 tsIndex) internal view returns(uint256) {
        uint256 key = (self.list.exists(tsIndex)) ? tsIndex : getLessIndex(self, tsIndex);
        return self.items[key].active;
    }
    
function justInsertKey(Data storage self, uint256 tsIndex) internal {
    if (!self.list.exists(tsIndex)) {
        self.list.insert(tsIndex);
    }
}


function getRoot(Data storage self) public view returns(uint256) {
    return self.list.root;
}
function getExists(Data storage self, uint256 tsIndex) public view returns(bool) {
    return self.list.exists(tsIndex);
}  
function getNext(Data storage self, uint256 tsIndex) public view returns(uint256) {
    return self.list.next(tsIndex);
}
function getPrev(Data storage self, uint256 tsIndex) public view returns(uint256) {
    return self.list.prev(tsIndex);
}  
function getNode(Data storage self, uint256 tsIndex) public view returns(uint256,uint256,uint256,uint256,bool) {
    return  self.list.getNode(tsIndex);
    
}
    function getLessIndex(Data storage self, uint256 tsIndex) internal view returns (uint256 key) {
        uint256 i = self.list.root;
        uint256 _parent;
        uint256 _prev;
        uint256 _next;
        key = 0;
        (i,_parent,_prev,_next,) = self.list.getNode(i);
        while (i != 0) {
            
            if (tsIndex < i) {
                i = _prev;
            } else if (tsIndex > i && _next == 0) {
                key = i;
                break;
            } else if (tsIndex > i) {
                i = _next;
            } else if (tsIndex == i) {
                key = i;
                break;
            }
            (i,_parent,_prev,_next,) = self.list.getNode(i);
        }
       
    }
    
    function sync(Data storage self) internal {
        uint256 currentInterval = getCurrentInterval(self);
        
        uint256 i = self.lastSyncIndex;
        if (self.lastSyncIndex == 0) {
            i = self.list.first();
        }
        
        while (i > currentInterval && i != 0) {
            
            self.items[i].active = self.items[i].active.sub(self.items[i].ended);
            
            i = self.list.next(i);
        }
        
        if (i != 0) {
            self.lastSyncIndex = i;
        }
        
    
        
    }
    
    function getCurrentInterval(Data storage self) internal view returns(uint256) {
        return getIndexInterval(block.timestamp, self.interval);
    }
    
    function getIndexInterval(uint256 ts, uint256 interval) private pure returns(uint256) {
        return (ts).div(interval).mul(interval);
    }
}