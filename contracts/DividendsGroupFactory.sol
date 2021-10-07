// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./FactoryBase.sol";
import "./interfaces/IDividendsGroupContract.sol";

/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 */
contract DividendsFactory is FactoryBase {
    
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------

    /**
     * init method
     */
    function init(
        address _dividendsGroupContractInstance
    ) 
        public 
        initializer 
    {
        __FactoryBase_init(_dividendsGroupContractInstance);
    }
    
    function produceInstance(
        uint256 interval
    ) 
        public 
        returns(address) 
    {
        address proxy = _produce();
        IDividendsGroupContract(proxy).initialize(interval);
        OwnableUpgradeable(proxy).transferOwnership(_getProducedSender());
        return proxy;
    }
    
    /**
     * make all instances belong to address(this)
     */
    // function _getProducedSender() internal override returns(address) {
    //     return msg.sender();
    // }
    
    function produceDividendsList(address sender) public view returns(address[] memory) {
        return producedList(sender);
    }
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    
    //---------------------------------------------------------------------------------
    // external section
    //---------------------------------------------------------------------------------
}