// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


abstract contract FactoryBase is OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    address contractInstance;
    mapping(address => EnumerableSetUpgradeable.AddressSet) list;
    event Produced(address caller, address addr);
  
    function __FactoryBase_init(address _contractInstance) internal initializer  {
        __Ownable_init();
        contractInstance = _contractInstance;
    }
    
    function producedList(
        address sender
    )
        internal
        view
        returns(address[] memory)
    {
        uint256 count = list[sender].length();
        address[] memory ret = new address[](count);
        for (uint256 i=0; i<count; i++) {
            ret[i] = list[sender].at(i);
        }
        return ret;
    }
    
    function isProducedBy(
        address sender,
        address instance
    )
        internal
        view
        returns(bool)
    {
        return list[sender].contains(instance);
        
    }
    
    
    function _produce() internal returns(address) {
        address proxy = createClone(address(contractInstance));

        address sender = _getProducedSender();
        
        emit Produced(sender, proxy);
        list[sender].add(proxy);

        return proxy;
    }
    
    function _getProducedSender() internal virtual returns(address) {
        return msg.sender;
    }
    
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
    
    
}