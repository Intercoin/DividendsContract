// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./erc777/ERC777Layer.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "./lib/BokkyPooBahsRedBlackTreeLibrary.sol";
//import "./interfaces/src20/ISRC20.sol";
//import "./Minimums.sol";

contract T {
    using SafeMath for uint256;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    
    uint256 i;
    uint256 i2;
    BokkyPooBahsRedBlackTreeLibrary.Tree intervals;
    // function set() public {
    //     uint256 j;
    //     for (j = 0; j < 5; j = j.add(1)) {
    //         i2 = j;
    //     }    
    //     i = j;
    // }
    // function get() public view returns(uint256,uint256) {
    //     return (i,i2);
    // }
    
    function set(uint256 i) public {
        if (intervals.exists(i)) {
        } else {
        intervals.insert(i);
        }
        
    }
    
    function unset(uint256 i) public {
        if (intervals.exists(i)) {
            intervals.remove(i);
        } else {
        
        }
        
    }
    
    function get() public view returns(uint256[] memory) {
        uint256 j;
        uint256 len;
        uint256 next;
        
        next = intervals.first();
        while (next != 0) {
            len += 1;
            next = intervals.next(next);
        }    


        uint256[] memory ret = new uint256[](len);
        uint256 counter;
        next = intervals.first();
            while (next != 0) {
                ret[counter] = next;
                counter = counter+1;
                next = intervals.next(next);
            } 
        
        return ret;
    }
    
    
}
// /*
//  * @title TransferRules contract
//  * @dev Contract that is checking if on-chain rules for token transfers are concluded.
//  */
contract Dividends is Ownable, ERC777Layer, IERC777Recipient {
    
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
	using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
	
    address token;
    uint256 duration;
    uint256 interval;
    uint256 multiplier;
    
    // index stored when contract deployed
    uint256 startedIndexInterval;
    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    
    event Staked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    /*
    struct UPool {
        uint256 shares;
        //uint256 accomulatedDividendsForPeriod;
        //uint256 accomulatedDividendsTotal;
        uint256 exists;
    }
    
    struct User {
        mapping(uint256 => UPool) userPool;
        uint256 lastClaimRedeemTime;
    }
    
    mapping(address => User) users;
    
    */
    
    struct Stake {
        uint256 started;
        uint256 ended;
        uint256 delta; // active(opened) shares at current interval_
        uint256 init; // flag setup in '1'(true) when creating new stake interval and sum started value from previous
    }
    struct StakeData {
        mapping(uint256 => Stake) stakes;
        uint256 previousIndex;
    }
    
    StakeData total;
    
    struct UserStake {
        StakeData total;
        BokkyPooBahsRedBlackTreeLibrary.Tree intervals;
        uint256 lastClaimRedeemTime;
        // uint256 lastDeltaTotal;
        // uint256 lastDeltaUser;
    }
    
    mapping(address => UserStake) users;
    
    
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 interval_, // * interval: WEEK by default
        uint256 duration_, // * duration: 52 (intervals)
        uint256 multiplier_,
        address token_
    ) 
        ERC777Layer(name_, symbol_, defaultOperators_)
    {
        
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        
        interval = interval_;
        duration = duration_;
        multiplier = multiplier_;
        token = token_;
        
        if (duration == 0) { duration = 52; }
        if (interval == 0) { interval = 604800; }
        
        startedIndexInterval = getCurrentIndexInterval();
  
        //make initial setting up for total node
        total.previousIndex = startedIndexInterval;
        total.stakes[startedIndexInterval] = Stake({
            started: 0,
            ended: 0,
            delta: 0,
            init: 1
        });
    }
    
// address a1;
// address a2;
// address a3;
// function get() public view returns(address,address,address) {
//     return (a1,a2,a3);
// }
    
    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) 
        override
        external
    {
        // a1 = operator;
        // a2 = from;
        // a3 = to;
        
        if (msg.sender == token) {
            
            stake(from, amount);
            
        }
    }
    
    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        
        // if (from == address(0)) {
            
        // }
        
        super._move(operator, from, to, amount, userData, operatorData);
        // store balances into buckets
        
        //uint256 currentIndexInterval = getCurrentIndexInterval();
        
        
        if (from != address(0)) {
            // users[from].userPool[currentIndexInterval].shares = balanceOf(from);
            // users[from].userPool[currentIndexInterval].exists = 1;
        }
        if (to != address(0)) {
            // uint256 i = currentIndexInterval;
            
            // users[to].userPool[i].shares = balanceOf(to);
            // users[to].userPool[i].exists = 1;
            
        }
        
        //totalShares[currentIndexInterval] = totalSupply();
    }
    
    function stake(
        address addr, 
        uint256 amount
    )
        internal
    {
        require(amount != 0, "wrong amount");
        
        _mint(addr, amount, "", "");
        
        // define intervals
        uint256 intervalStarted = getCurrentIndexInterval();
        uint256 intervalEnded = intervalStarted.add(duration);
        _stakeAdd(addr, amount, intervalStarted, intervalEnded);
        
        emit Staked(addr, amount);
    }
    
    function _stakeAdd(
        address addr, 
        uint256 amount,
        uint256 intervalStarted,
        uint256 intervalEnded
    )
        internal
    {
        // define intervals
        // uint256 intervalStarted = getCurrentIndexInterval();
        // uint256 intervalEnded = intervalStarted.add(duration);
        
        // ----------------------
        // store to total
        // note: seems that delta are the same, but it's not true. 
        //    started  - sum of all started in the pointed period
        //    delta - accumulated value from previuos steps and represent all active shares 
        if (total.stakes[intervalStarted].init == 0) {
            total.stakes[intervalStarted].delta = total.stakes[total.previousIndex].delta
                .sub(
                    total.stakes[intervalStarted].ended
                );
            total.previousIndex = intervalStarted;
            total.stakes[intervalStarted].init = 1;
        }
        
        total.stakes[intervalStarted].started = total.stakes[intervalStarted].started.add(amount);
        total.stakes[intervalEnded].ended = total.stakes[intervalEnded].ended.add(amount);
        
        total.stakes[intervalStarted].delta = total.stakes[intervalStarted].delta.add(amount);
        // ----------------------
        
        // store to user
        if (users[addr].total.stakes[intervalStarted].init == 0) {
            users[addr].total.stakes[intervalStarted].delta = users[addr].total.stakes[users[addr].total.previousIndex].delta
                .sub(
                    users[addr].total.stakes[intervalStarted].ended
                );
            users[addr].total.previousIndex = intervalStarted;
            users[addr].total.stakes[intervalStarted].init = 1;
        }
        users[addr].total.stakes[intervalStarted].started = users[addr].total.stakes[intervalStarted].started.add(amount);
        users[addr].total.stakes[intervalEnded].ended = users[addr].total.stakes[intervalEnded].ended.add(amount);
        
        users[addr].total.stakes[intervalStarted].delta = users[addr].total.stakes[intervalStarted].delta.add(amount);
        
        /// added intervals
        if (!users[addr].intervals.exists(intervalStarted)) {
            users[addr].intervals.insert(intervalStarted);
        }
        if (!users[addr].intervals.exists(intervalEnded)) {
            users[addr].intervals.insert(intervalEnded);
        }
        
    }
    
    function getShares(address addr, uint256 from, uint256 to) public view returns(uint256 ret) {
        uint256 next = users[addr].intervals.first();
        
        while (next != 0) {
            if ((from <= next) && (to >= next)) {
                ret = users[addr].total.stakes[next].delta;
            }
            
            if (to < next) {
                break;
            }
            
            next = users[addr].intervals.next(next);
        } 
    }
    function calculateDividends(
        address addr
    )
        internal
    {
        // started 0
        // 0-0
        // 0-1
        // uint256 currentIndexInterval = getCurrentIndexInterval();
        // uint256 lastClaimRedeemTime = users[addr].lastClaimRedeemTime;
        // if (currentIndexInterval > lastClaimRedeemTime) {
            
            
            
        //     uint256 i;
            
        //     uint256 balance;
        //     uint256 accomulatedDividendsForPeriod;
        //     uint256 accomulatedDividendsTotal;
            
        //     balance = users[addr].userPool[lastClaimRedeemTime].balance;
        //     accomulatedDividendsForPeriod = users[addr].userPool[lastClaimRedeemTime].accomulatedDividendsForPeriod;
        //     accomulatedDividendsTotal = users[addr].userPool[lastClaimRedeemTime].accomulatedDividendsTotal;
        
        //     for (i = lastClaimRedeemTime; i < currentIndexInterval; i = i.add(stakeDuration)) {
        //         if (users[addr].userPool[i].exists == 1) {
                    
                    
        //             balance = users[addr].userPool[i].balance;
        //             accomulatedDividendsForPeriod = users[addr].userPool[i].accomulatedDividendsForPeriod;
        //             accomulatedDividendsTotal = users[addr].userPool[i].accomulatedDividendsTotal;
        //         }
        //         //users[addr].userPool[i].accomulatedDividendsForPeriod = 
        //     }
        // }
    }
    
    /*
    mapping(uint256 => uint256) totalBalances;
    
     struct Stake {
        uint256 totalStarted;
        uint256 totalEnded;
    }
    struct UserStake {
        mapping(uint256 => Stake) userStakes;
        uint256 lastClaimRedeemTime;
    }
    
    mapping(address => User) users;
    
    */
    function getCurrentIndexInterval() internal view returns(uint256) {
        return (block.timestamp).div(interval).mul(interval);
    }
    
    function getNextIndexInterval() internal view returns(uint256) {
        return getCurrentIndexInterval().add(interval);
    }
    
    function claim()
        public
    {
        // calculate 
        
        
        //calculateDividends(_msgSender());
    }
    
    function redeem()
        public
    {
        //calculateDividends(_msgSender());
    }
/*
    
    function claim()
        public
        override 
    {
        address addr =_msgSender();
        (uint256 retMinimum,) = getMinimum(addr);
        uint256 amount = balanceOf(_msgSender()).sub(retMinimum);
        
        require(amount != 0, "insufficient balance");
        
        uint256 lastClaimTime = lastClaimRedeemTime[addr];
        lastClaimRedeemTime[addr] = block.timestamp;
        
        // (amount able to redeem) * (seconds pass from last claim) / 1e10
        uint256 benefits = amount.mul(block.timestamp.sub(lastClaimTime)).div(1e10);
        
        require(benefits != 0, "insufficient balance");
        
        require(ISRC20(_src20).executeTransfer(address(this), addr, benefits), "SRC20 transfer failed");
        
        emit Claimed(addr, benefits);
    }
    
    function redeem()
        public
        override 
    {
        address addr =_msgSender();
        
        (uint256 retMinimum,) = getMinimum(addr);
        
        uint256 amount = balanceOf(addr).sub(retMinimum);
        require(amount != 0, "insufficient balance");
        _burn(addr, amount);

        require(ISRC20(_src20).executeTransfer(address(this), addr, amount), "SRC20 transfer failed");
        
        emit Redeemed(_msgSender(), amount);
    }
    
    function cleanSRC() public override onlyOwner() {
        _src20 = address(0);
    }
    
    function setSRC(address src20) public override onlyOwner() returns (bool) {
        _src20 = src20;
        
        return true;
    }
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        
        if (
            (sender == address(0)) && (recipient != address(0))
        ) {
            // mint
            minimumsAdd(recipient, amount, block.timestamp.add(stakeDuration), true);
        } else {
            // burn
            (uint256 retMinimum,) = getMinimum(sender);
            uint256 tmpAmount = balanceOf(sender).sub(retMinimum);
            require(tmpAmount >= amount, "insufficient balance");
            // burn or usual transfer
            minimumsTransfer(
                sender, 
                recipient, 
                amount, 
                false, 
                0
            );
        
        }
        
    }
    */
}