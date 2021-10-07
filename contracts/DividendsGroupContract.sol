// 2) Make DividendsGroupFactory which will create a DividendsGroupContract. It will have methods like this:

// All DividendContracts for same owner must have same interval, or revert

// add(dividendsContractsArray) ownerOnly
// getDividendContracts() returns array of address

// 3) Also implement DividendsGroupContract.deposit(token, amount) method which will transfer (we are assuming allowance has been made) ERC20 tokens to the contract. 
// It will then also call group.disburse() method

// 4) The group.disburse() method that will have cur =  floor(block.timestamp / interval) * interval and then it would loop through all the dividendsContracts byOwner and get the sum of totalShares(cur). 
// It would transfer all accumulated tokens (including WETH and any accumulated native ETH/BNB) proportionally to all dividendsContracts in group, ie totalShares(cur) / totalSharesSum(cur) * amount for each one, 
//and then also call:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IDividendsGroupContract.sol";
import "./interfaces/IDividendsContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";

contract DividendsGroupContract is IDividendsGroupContract, OwnableUpgradeable {
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    //---------------------------------------------------------------------------------
    // variables section
    //---------------------------------------------------------------------------------
    EnumerableSetUpgradeable.AddressSet dividendsContracts;
    uint256 public interval;
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------
    function initialize(
        uint256 interval_
    ) 
        public 
        initializer
        override
    {
        __DividendsGroupContract_init(interval_);
        
    }
    
    function addDividendContracts(
        address[] memory dividendsContractsArray
    ) 
        onlyOwner 
        public 
    {
        uint256 len;
        for(uint256 i = 0; i< dividendsContractsArray.length; i++) {
            len = IDividendsContract(dividendsContractsArray[i]).getInterval();
            require(interval == len, 'wrong interval in dividendsContract');
            dividendsContracts.add(dividendsContractsArray[i]);
            
        }
    }
    function removeDividendContracts(
        address[] memory dividendsContractsArray
    ) 
        onlyOwner 
        public 
    {
        for(uint256 i = 0; i< dividendsContractsArray.length; i++) {
            dividendsContracts.remove(dividendsContractsArray[i]);
            
        }
    }
    
    function getDividendContracts(
    ) 
        public 
        view 
        returns (address[] memory) 
    {
        uint256 len = dividendsContracts.length();
        address[] memory ret = new address[](len);
        for(uint256 i = 0; i< len; i++) {
            ret[i] = dividendsContracts.at(i);
        }
        return ret;
    }

    /**
     * disburse amount to each dividendsContracts
     */
    function disburse(
        uint256 amount
    ) 
        onlyOwner 
        public 
    {
        // TBD
        
    }
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    
    function __DividendsGroupContract_init(
        uint256 interval_
    ) 
        internal
        initializer 
    {
        __Ownable_init();
        
        require(interval_ != 0, 'wrong interval');
        interval = interval_;
    }
    
}
