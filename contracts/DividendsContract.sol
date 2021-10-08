// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./erc777/ERC777LayerUpgradeable.sol";



import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "./lib/BokkyPooBahsRedBlackTreeLibrary.sol";
import "./interfaces/IDividendsContract.sol";
 
contract DividendsContract is OwnableUpgradeable, ERC777LayerUpgradeable, IERC777RecipientUpgradeable, IDividendsContract {
    
	using SafeMathUpgradeable for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    //using Address for address;
	using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
	
	//---------------------------------------------------------------------------------
    // variables section
    //---------------------------------------------------------------------------------
    
	uint256 private stakeMultiplier;
	
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
    
    struct Stake {
        uint256 shares;
        mapping(address => uint256) dividends;
        
    }
    
    struct StakeData {
        mapping(uint256 => Stake) stakes;
        
        // mapping(uint256 => uint256) shares;
        // mapping(uint256 => mapping(address => uint256)) dividends;
        // mapping(uint256 => uint256) sumCalculated;
        
        BokkyPooBahsRedBlackTreeLibrary.Tree stakeIndexes;
        
        uint256 lastDisbursedIndex;
    }
    
    StakeData total;
    
    
    struct UserStake {
        uint256 shares; // sum shares for period
        uint256 sharesStarted;
        uint256 sharesEnded;
    }
    
    struct UserStakeData {
        mapping(uint256 => UserStake) stakes;
        BokkyPooBahsRedBlackTreeLibrary.Tree stakeIndexes;
        
        uint256 lastSyncIndex;
        
        uint256 lastClaimRedeemTime;
        // uint256 lastDeltaTotal;
        // uint256 lastDeltaUser;
    }
    
    mapping(address => UserStakeData) users;
    
    EnumerableSetUpgradeable.AddressSet whitelist;
    
    function initialize(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 interval_, // * interval: WEEK by default
        uint256 duration_, // * duration: 52 (intervals)
        uint256 multiplier_,
        address token_,
        address[] memory whitelist_
    ) 
        public 
        initializer
        override
    {
        __DividendsContract_init(name_, symbol_, defaultOperators_, interval_, duration_, multiplier_, token_, whitelist_);
        
    }
    
/*
1-5
5-10
8-13

*/    
    
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------
    function getInterval() public view override returns(uint256) {
        return interval;
    }
    
    // claim dividends
    function claim()
        public
    {
        address addr = msg.sender;
        _syncUserBuckets(addr);
        
        uint256 len = whitelist.length();
        uint256[] memory amountToPay = new uint256[](len);
        
        uint256 intervalCurrent = getIndexInterval(block.timestamp);
        uint256 i = users[addr].lastClaimRedeemTime;
        while (i < intervalCurrent && i < total.lastDisbursedIndex) {
            if (total.stakes[i].shares != 0) {
                for(uint256 j = 0; i < whitelist.length(); i++) {
                    if (total.stakes[i].dividends[whitelist.at(j)] != 0) {
                        // (dividends/total)*user   = user*dividends/total
                        amountToPay[j] = amountToPay[j].add(
                                            users[addr].stakes[i].shares
                                                .mul(total.stakes[i].dividends[whitelist.at(j)])
                                                .div(total.stakes[i].shares)
                                        );
                    }
                }
            }
        
            
            users[addr].lastClaimRedeemTime = i;
            i = users[addr].stakeIndexes.next(i);
            if (i == 0) {
                break;
            }
        }
        
        // try to pay
        for(uint256 j = 0; i < whitelist.length(); i++) {
            if (amountToPay[j] != 0) {
                IERC20Upgradeable(whitelist.at(i)).transfer(addr, amountToPay[j]);
            }
        }
        
    }
    
    function redeem()
        public
    {
        //calculateDividends(_msgSender());
    }
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    
    /**
     * init internal
     */
    function __DividendsContract_init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 interval_, // * interval: WEEK by default
        uint256 duration_, // * duration: 52 (intervals)
        uint256 multiplier_,
        address token_,
        address[] memory whitelist_
    ) 
        internal
        initializer 
    {
        __Ownable_init();
        __ERC777LayerUpgradeable_init(name_, symbol_, defaultOperators_);
        
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        
        interval = interval_;
        duration = duration_;
        multiplier = multiplier_;
        token = token_;
        
        if (duration == 0) { duration = 52; }
        if (interval == 0) { interval = 604800; }
        
        stakeMultiplier = 1_000_000_000;
        
        startedIndexInterval = getIndexInterval(block.timestamp);
  
        //make initial setting up for total node
        // total.stakes[startedIndexInterval] = Stake({
        //     shares: 0
        // });
        total.stakes[startedIndexInterval].shares = 0;
        //----
        
        total.stakeIndexes.insert(startedIndexInterval);
        
        
        // whitelist
        for (uint256 i =0; i<whitelist_.length; i++) {
            whitelist.add(whitelist_[i]);
        }

    }
// function _beforeTokenTransfer(
//         address sender,
//         address recipient,
//         uint256 amount
//     ) internal override {
        
//         if (
//             (sender == address(0)) && (recipient != address(0))
//         ) {
//             // mint
//             minimumsAdd(recipient, amount, block.timestamp.add(stakeDuration), true);
//         } else {
//             // burn
//             (uint256 retMinimum,) = getMinimum(sender);
//             uint256 tmpAmount = balanceOf(sender).sub(retMinimum);
//             require(tmpAmount >= amount, "insufficient balance");
//             // burn or usual transfer
//         minimumsTransfer(
//                 sender, 
//                 recipient, 
//                 amount, 
//                 false, 
//                 0
//             );
        
//         }
        
//     }    
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
        
        
        // store balances into buckets
        
        //uint256 currentIndexInterval = getCurrentIndexInterval();
        
        
        if (from == address(0) || to == address(0)) {
            super._move(operator, from, to, amount, userData, operatorData);
        } else {
            revert('TBD: transfer was temporary disabled');
        }
            
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
        uint256 intervalStarted = getIndexInterval(block.timestamp);
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
        _syncUserBuckets(addr);
        
        if (!total.stakeIndexes.exists(intervalStarted)) {
            total.stakeIndexes.insert(intervalStarted);
        }
        total.stakes[intervalStarted].shares = total.stakes[intervalStarted].shares.add(amount);

        // ----------------------
        
        // store to user
        if (!users[addr].stakeIndexes.exists(intervalStarted)) {
            users[addr].stakeIndexes.insert(intervalStarted);
        }
        users[addr].stakes[intervalStarted].shares = users[addr].stakes[intervalStarted].shares.add(amount);

        // added ended intervals
        if (!users[addr].stakeIndexes.exists(intervalEnded)) {
            users[addr].stakeIndexes.insert(intervalEnded);
        }
        users[addr].stakes[intervalEnded].sharesEnded = users[addr].stakes[intervalEnded].sharesEnded.add(amount);
        
    }
    
    function _disburse(
        address token_, 
        uint256 amount_
    ) 
        internal 
    {
        uint256 intervalCurrent = getIndexInterval(block.timestamp);
        
        // if current disburse inteval not equal with last. we check totalShares. if totalShares == 0 we move dividends from that interval to current
        if (total.lastDisbursedIndex != intervalCurrent) {
            if (total.stakes[total.lastDisbursedIndex].shares == 0) {
                for(uint256 i = 0; i < whitelist.length(); i++) {
                    total.stakes[intervalCurrent].dividends[whitelist.at(i)] = total.stakes[total.lastDisbursedIndex].dividends[whitelist.at(i)];
                }
            }
            total.lastDisbursedIndex == intervalCurrent;
        }
        
        // save dividends
        total.stakes[intervalCurrent].dividends[token_] = total.stakes[intervalCurrent].dividends[token_].add(amount_);

    }
    
    /**
     * methdo that ewill sync [usershares] variable to last condition
     */
    function _syncUserBuckets(
        address addr
    ) 
        internal 
    {
        uint256 intervalCurrent = getIndexInterval(block.timestamp);
        if (users[addr].lastSyncIndex == intervalCurrent) {
            
        } else {
            uint256 i = users[addr].lastSyncIndex;
            while (i < intervalCurrent) {
                users[addr].stakes[i].shares = users[addr].stakes[i].shares.sub(users[addr].stakes[i].sharesEnded);
                users[addr].lastSyncIndex = i;
                i = users[addr].stakeIndexes.next(i);
                if (i == 0) {
                    break;
                }
            }
            users[addr].lastSyncIndex = intervalCurrent;
        }
        
        
        /*
         struct UserStake {
        uint256 shares; // sum shares for period
        uint256 sharesStarted;
        uint256 sharesEnded;
    }
    
    struct UserStakeData {
        mapping(uint256 => UserStake) stakes;
        BokkyPooBahsRedBlackTreeLibrary.Tree stakeIndexes;
        
        uint256 lastSyncIndex;
        
        uint256 lastClaimRedeemTime;
        // uint256 lastDeltaTotal;
        // uint256 lastDeltaUser;
    }
    
    mapping(address => UserStakeData) users;
        */
    }
    //---------------------------------------------------------------------------------
    // external section
    //---------------------------------------------------------------------------------
    
// address a1;
// address a2;
// address a3;
// function get() public view returns(address,address,address) {
//     return (a1,a2,a3);
// }
    function disburse(
        address token_, 
        uint256 amount_
    ) 
        external 
        override 
    {
        require(whitelist.contains(token_), "invalid token_");
        
        // try to check allowance
        uint256 _allowedAmount = IERC20Upgradeable(token_).allowance(_msgSender(), address(this));
        require((_allowedAmount >= amount_), "Amount exceeds allowed balance");
        // try to get
        bool success = IERC20Upgradeable(token_).transferFrom(_msgSender(), address(this), amount_);
        require(success == true, "Transfer tokens were failed"); 
        
        // save dividends
        _disburse(token_, amount_);
        

    }
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
            
        } else if (whitelist.contains(msg.sender)) {

            // save dividends
            _disburse(msg.sender, amount);
        } else {
            revert("unsupported tokens");
        }
        
    }
    
    
    
    // function _disburse() internal {
    //     uint256 lastIntervalToCalculate = getPrevIndexInterval(block.timestamp);
    //     uint256 i = total.stakeIndexes.next(total.lastDisbursedIndex);
    //     while (i <= lastIntervalToCalculate || i == 0) {
            
    //         total.stakes[i].sumCalculated = total.stakes[total.lastDisbursedIndex].sumCalculated
    //             .add(
    //                 stakeMultiplier
    //                     .mul(total.stakes[i].dividends)
    //                     .div(total.stakes[i].shares)
    //                 );
    //         total.lastDisbursedIndex = i;
    //         i = total.stakeIndexes.next(i);
    //     }
    //     // after that total.lastDisbursedIndex = lastIntervalToCalculate;
    // }

    
// interval        6   7   8 
    
// sumDividends    3   8   16
// sumShares       4   10  19
    
// dividends       3   5   8
// shares          4   6   9 

// sum          0.75 1.58 2.47
    
    
    // get sum shares at interval
    // loop need if we have check for none exists buckets yet
    function getTotalShares(uint256 timestamp) public view returns(uint256) {
        uint256 intervalIndex = getIndexInterval(timestamp);
        while (!total.stakeIndexes.exists(intervalIndex)) {
            intervalIndex = getPrevIndexInterval(intervalIndex);
        }
        return total.stakes[intervalIndex].shares;
    }
    
    // function getTotalUserShares(address addr, uint256 timestamp) public view returns(uint256) {
    //     uint256 intervalIndex = getIndexInterval(timestamp);
    //     while (users[addr].total.stakes[intervalIndex].init == 0) {
    //         intervalIndex = getPrevIndexInterval(intervalIndex);
    //     }
    //     return users[addr].total.stakes[intervalIndex].totalShares;
    // }
    
    // function getTotalUserShares(address addr, uint256 timestamp) public view returns(uint256) {
    //     uint256 intervalIndex = getIndexInterval(timestamp);
    //     while (users[addr].total.stakes[intervalIndex].init == 0) {
    //         intervalIndex = getPrevIndexInterval(intervalIndex);
    //     }
    //     return users[addr].total.stakes[intervalIndex].totalShares;
    // }
    
/*
1-10    1   sum=1   
5-15    5   sum=6   
10-20   10  sum=16  
20-30   2   sum=18  
25-35   5   sum=23  
*/    
    function getShares(address addr, uint256 from, uint256 to) public view returns(uint256 ret) {
        // uint256 next = users[addr].intervals.first();
        
        // while (next != 0) {
        //     if ((from <= next) && (to >= next)) {
        //         ret = users[addr].total.stakes[next].delta;
        //     }
            
        //     if (to < next) {
        //         break;
        //     }
            
        //     next = users[addr].intervals.next(next);
        // } 
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
    function getIndexInterval(uint256 ts) internal view returns(uint256) {
        return (ts).div(interval).mul(interval);
    }
    
    function getNextIndexInterval(uint256 ts) internal view returns(uint256) {
        return getIndexInterval(ts).add(interval);
    }
    function getPrevIndexInterval(uint256 ts) internal view returns(uint256) {
        return getIndexInterval(ts).sub(interval);
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