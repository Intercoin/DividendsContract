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
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/IDividendsGroupContract.sol";
import "./interfaces/IDividendsContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";

contract DividendsGroupContract is IDividendsGroupContract, OwnableUpgradeable, IERC777RecipientUpgradeable {
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable for uint256;
    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    event Distribute(address token, address dividendContract, uint256 amount);
    
    //---------------------------------------------------------------------------------
    // variables section
    //---------------------------------------------------------------------------------
    EnumerableSetUpgradeable.AddressSet dividendsContracts;
    uint256 public interval;
    address public token;
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------
    function initialize(
        address token_,
        uint256 interval_
    ) 
        public 
        initializer
        override
    {
        __DividendsGroupContract_init(token_, interval_);
        
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
        
        // validate amount
        // TBD
        // ---------
        
        uint256 len = dividendsContracts.length();
        uint256[] memory sum = new uint256[](len);
        //uint256[] memory multipliers = new uint256[](len);
        uint256 sumTotal;
        uint256 indexInterval = getIndexInterval(block.timestamp);
        
        for(uint256 i = 0; i< len; i++) {
            sum[i] = (IDividendsContract(dividendsContracts.at(i)).getMultiplier())
                    .mul(
                        IDividendsContract(dividendsContracts.at(i)).getSharesSum(indexInterval)
                    )
            ;
            sumTotal = sumTotal.add(sum[i]);

        }
        
        require(sumTotal > 0, "total is equal zero") ;
        uint256 amount2send;
        for(uint256 i = 0; i< len; i++) {
            amount2send = amount.mul(sum[i]).div(sumTotal);
            if (amount2send > 0) {
                IERC20Upgradeable(token).transfer(dividendsContracts.at(i), amount2send);
                emit Distribute(token, dividendsContracts.at(i), amount2send);
            }
            
        }
    }
    
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    
    function __DividendsGroupContract_init(
        address token_,
        uint256 interval_
    ) 
        internal
        initializer 
    {
        __Ownable_init();
        
        require(interval_ != 0, 'wrong interval');
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
        
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        
        token = token_;
        interval = interval_;
    }
    
    function getIndexInterval(uint256 ts) public view returns(uint256) {
        return (ts).div(interval).mul(interval);
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
       
        
    }
}
