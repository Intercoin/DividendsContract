// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DividendsBase.sol";

 
contract DividendsContract is DividendsBase {
    
	using SafeMathUpgradeable for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
	using SumLibrary for SumLibrary.Data;
    
	//---------------------------------------------------------------------------------
    // variables section
    //---------------------------------------------------------------------------------
    
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
        virtual
        initializer
        override
    {
        
        __DividendsContract_init(name_, symbol_, defaultOperators_, interval_, duration_, multiplier_, token_, whitelist_);
        
    }
   
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------
    function stake(
        uint256 amount
    )
        public
    {
        
        bool success = IERC20Upgradeable(token).transferFrom(_msgSender(), address(this), amount);
        require(success == true, "");
        
        _mint(_msgSender(), amount, "", "");
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
        __DividendsBase_init(name_, symbol_, defaultOperators_, interval_, duration_, multiplier_, token_, whitelist_);
        
    }

  
    //---------------------------------------------------------------------------------
    // external section
    //---------------------------------------------------------------------------------
    
    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) 
        override
        virtual
        external
    {
        // a1 = operator;
        // a2 = from;
        // a3 = to;
        
        // msg.sender here is tokencontract that send from
        
        if (msg.sender == token) {
            
            _stake(from, amount);
            
        } else if (whitelist.contains(msg.sender)) {

            // save dividends
            _disburse(msg.sender, amount);
        } else {
            revert("unsupported tokens");
        }
        
    }

    

}