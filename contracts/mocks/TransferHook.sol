// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IHook.sol";
import "../interfaces/IHookCaller.sol";

contract TransferHookMock is Ownable, IHook {
    
    address public hookCaller;
  
    function doSetup(
    ) 
        external 
        override
    {
        require(hookCaller == address(0), "already setup");
        hookCaller = _msgSender();
    }
    function clearSetup(
    ) 
        public 
        override
        onlyOwner()
    {
        hookCaller = address(0);
    } 
    
    function doTransfer(
        address operator, 
        address from, 
        address to, 
        uint256 amount, 
        bytes memory userData, 
        bytes memory operatorData
    ) 
        external 
        override
    {
        
        IHookCaller(hookCaller).executeTransfer(operator, from, to, amount/2, userData, operatorData);
        IHookCaller(hookCaller).executeTransfer(operator, from, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, amount/2, userData, operatorData);
    }
}