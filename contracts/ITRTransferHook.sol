// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./src20/BaseTransferRule.sol";
import "./FactoryBase.sol";
import "./interfaces/IDividends.sol";

/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 */
contract ITRTransferHook is BaseTransferRule, FactoryBase {
    using SafeMathUpgradeable for uint256;
    
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------

    /**
     * init method
     */
    function init(
        address _dividentContractInstance
    ) 
        public 
        initializer 
    {
        __ITRTransferHook_init();
        __FactoryBase_init(_dividentContractInstance);
    }
    
    function produceDividendsInstance(
        string memory name,
        string memory symbol,
        uint256 duration
    ) public returns(address) {
        address proxy = _produce();
        IDividends(proxy).initialize(name, symbol, duration, _src20);
        return proxy;
    }
    
    /**
     * make all instances belong to address(this)
     */
    function _getProducedSender() internal override returns(address) {
        return address(this);
    }
    
    function produceDividendsList(address sender) public view returns(address[] memory) {
        return producedList(sender);
    }
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    
    /**
     * init internal
     */
    function __ITRTransferHook_init(
    ) 
        internal
        initializer 
    {
        __BaseTransferRule_init();
        
    }
  
    //---------------------------------------------------------------------------------
    // external section
    //---------------------------------------------------------------------------------
    
    
    /**
    * @dev Do transfer and checks where funds should go. If both from and to are
    * on the whitelist funds should be transferred but if one of them are on the
    * grey list token-issuer/owner need to approve transfer.
    *
    * @param from The address to transfer from.
    * @param to The address to send tokens to.
    * @param value The amount of tokens to send.
    */
    function _doTransfer(
        address from, 
        address to, 
        uint256 value
    ) 
        override
        internal
        returns (
            address _from, 
            address _to, 
            uint256 _value
        ) 
    {
        
        (_from,_to,_value) = (from,to,value);
        
        if (isProducedBy(address(this), _to)) {
            IDividends(_to).stake(from, value);
        }
        
    }
    
    function cleanSRC() public override onlyOwner() {
        super.cleanSRC();
        // _src20 = address(0);
        // doTransferCaller = address(0);
        // //_setChain(address(0));
        
        address[] memory list = producedList(address(this));
        for (uint256 i=0; i<list.length; i++) {
            IDividends(list[i]).cleanSRC();
        }
    }
    function setSRC(address src20) override public returns (bool) {
        super.setSRC(src20);
        // require(doTransferCaller == address(0), "external contract already set");
        // require(address(_src20) == address(0), "external contract already set");
        // require(src20 != address(0), "src20 can not be zero");
        // doTransferCaller = _msgSender();
        // _src20 = src20;
        
        address[] memory list = producedList(address(this));
        for (uint256 i=0; i<list.length; i++) {
            IDividends(list[i]).setSRC(src20);
        }
        
        return true;
    }
}
