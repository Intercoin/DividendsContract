// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./FactoryBase.sol";
import "./interfaces/IDividendsContract.sol";

/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 */
contract DividendsFactory is FactoryBase {
    using SafeMathUpgradeable for uint256;
    
        //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------

    /**
     * init method
     */
    function init(
        address _dividendsContractInstance
    ) 
        public 
        initializer 
    {
        __FactoryBase_init(_dividendsContractInstance);
    }
    
    function produceInstance(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        uint256 interval, // * interval: WEEK by default
        uint256 duration, // * duration: 52 (intervals)
        uint256 multiplier,
        address token
    ) public returns(address) {
        address proxy = _produce();
        IDividendsContract(proxy).initialize(name, symbol, defaultOperators, interval, duration, multiplier, token);
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