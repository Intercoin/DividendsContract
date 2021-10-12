// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";

import "./erc777/ERC777LayerUpgradeable.sol";
import "./lib/SumLibrary.sol";
import "./interfaces/IDividendsContract.sol";
import "./Minimums.sol";

 
contract DividendsContract is OwnableUpgradeable, ERC777LayerUpgradeable, IERC777RecipientUpgradeable, IDividendsContract, Minimums {
    
	using SafeMathUpgradeable for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
	using SumLibrary for SumLibrary.Data;
    
	//---------------------------------------------------------------------------------
    // variables section
    //---------------------------------------------------------------------------------
    
	uint256 private stakeMultiplier;
	
    address token;
    uint256 duration;
    uint256 interval;
    uint256 multiplier;
    
    // percent of shares to lockup 
    uint256 lockupPeriod;
    // index stored when contract deployed
    uint256 startedIndexInterval;
    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    
    event Staked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    struct UserData {
        SumLibrary.Data balances;
        uint256 lastClaimedIndex;    
    }
    SumLibrary.Data totalShares;
    mapping(address => UserData) users;
    
    //      token        dividends / activeShares
    mapping(address => SumLibrary.Data) sumDividendsAndActiveShares;

    uint256 lastDisbursedIndex;
    

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
        __Minimums_init(interval_);
        
    }
   
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------
    function getInterval() public view override returns(uint256) {
        return interval;
    }
    function getMultiplier() public view override returns(uint256) {
        return multiplier;
    }
    function getSharesSum(uint256 intervalIndex) external view override returns(uint256) {
        return totalShares.get(intervalIndex);
    }
    
    
    
    
    // get sum shares at interval
    // loop need if we have check for none exists buckets yet
    function getTotalShares(uint256 timestamp) public view returns(uint256) {
        // uint256 intervalIndex = getIndexInterval(timestamp);
        // while (!total.stakeIndexes.exists(intervalIndex)) {
        //     intervalIndex = getPrevIndexInterval(intervalIndex);
        // }
        // return total.stakes[intervalIndex].shares;
    }

    
    
    
    
    
    
    
    // claim dividends
    function claim()
        public
    {
        
    // var total = 0;
    // for (i=_lastClaimedIndex; true; ++i) {
    //     for (dividendTokens as token) {
    //         var sum1 = sum[token].get(times[i]);
    //         var sum2 = sum[token].get(times[i+1]);
    //         total += (sum2 - sum1) * _amounts[msg.caller][i];
    //     }
    //     if (times[i] >= _lastDisburseTime) {
    //         // no more tokens to claim, for now
    //         break;
    //     }
    // }
    // lastClaimedIndex = i;
    // return total;
    
        address addr = msg.sender;
        uint256 len = whitelist.length();
        uint256[] memory amountToPay = new uint256[](len);
        uint256 intervalCurrent = getIndexInterval(block.timestamp);
        //uint256 i = users[addr].lastClaimRedeemTime;
        uint256 i = users[addr].lastClaimedIndex;
        
        // setup i is when the contract started
        if (i == 0) {
            i = startedIndexInterval;
        }
        
        uint256 totalSharesinInterval;
        while (i < intervalCurrent && i < lastDisbursedIndex) {
            totalSharesinInterval = totalShares.get(i);
            if (totalSharesinInterval != 0) {
                for(uint256 j = 0; i < whitelist.length(); i++) {
                        // (dividends/total)*user   = user*dividends/total
                        amountToPay[j] = amountToPay[j].add(
                            sumDividendsAndActiveShares[whitelist.at(j)].get(i)
                            .mul(users[addr].balances.get(i))
                        );
                }
            }
        
            
            users[addr].lastClaimedIndex = i;
            
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
        
        lockupPeriod = 100;// 1 % mul by 1e2
        
        startedIndexInterval = getIndexInterval(block.timestamp);
        lastDisbursedIndex = startedIndexInterval;
        //lastClaimedIndex = startedIndexInterval;
    
        // whitelist
        for (uint256 i =0; i<whitelist_.length; i++) {
            whitelist.add(whitelist_[i]);
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
        
        
        
        if (from == address(0) || to == address(0)) {
            
            
            super._move(operator, from, to, amount, userData, operatorData);
            
            if (from == address(0)) {
                // function minimumsAdd(address addr,uint256 amount, uint256 timestamp,bool gradual)
                minimumsAdd(to, amount.mul(lockupPeriod).div(10000), getIndexInterval(block.timestamp).add(interval),false);
            }
    
        } else {

            /**
             * 
             * @param from sender address
             * @param to destination address
             * @param value amount
             * @param reduceTimeDiff if true then all timestamp which more then minTimeDiff will reduce to minTimeDiff
             * @param minTimeDiff minimum lockup period time or if reduceTimeDiff==false it is time to left tokens
             */
            minimumsTransfer(from, to, amount);
            
            super._move(operator, from, to, amount, userData, operatorData);
            //revert('TBD: transfer was temporary disabled');
        }
            
    }
    
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        super._mint(account, amount, userData, operatorData);
        
        // define intervals
        //uint256 intervalCurrent = getIndexInterval(block.timestamp);
        (users[account].balances).add(balanceOf(account));
        totalShares.addSum(totalSupply());
        
        emit Staked(account, amount);
    }
    
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal override {
        super._burn(from, amount, data, operatorData);
        
        // define intervals
        //uint256 intervalCurrent = getIndexInterval(block.timestamp);
        (users[from].balances).add(balanceOf(from));
        totalShares.addSum(totalSupply());
    }
    
    function stake(
        address addr, 
        uint256 amount
    )
        internal
    {
        _mint(addr, amount, "", "");
    }
    
    /*
    sum[token].add(1e6 * amount / activeShares());
    */
    function _disburse(
        address token_, 
        uint256 amount_
    ) 
        internal 
    {
        uint256 intervalCurrent = getIndexInterval(block.timestamp);
        require (lastDisbursedIndex < intervalCurrent, "already disbursed");
        //if (lastDisbursedIndex < intervalCurrent) {
        sumDividendsAndActiveShares[token_].add(
            amount_
            .mul(stakeMultiplier)
            .div(
                totalShares.get(intervalCurrent)
                .sub(totalShares.get(lastDisbursedIndex))
            )
        );
        lastDisbursedIndex = intervalCurrent;
        //}
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

 
    // function getIndexInterval(uint256 ts) internal view returns(uint256) {
    //     return (ts).div(interval).mul(interval);
    // }
    
    // function getNextIndexInterval(uint256 ts) internal view returns(uint256) {
    //     return getIndexInterval(ts).add(interval);
    // }
    // function getPrevIndexInterval(uint256 ts) internal view returns(uint256) {
    //     return getIndexInterval(ts).sub(interval);
    // }
    

}