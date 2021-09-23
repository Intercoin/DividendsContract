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
        address sender,
        address recipient,
        uint256 amount
    ) 
        external 
        override
    {
        
        IHookCaller(hookCaller).executeTransfer(sender, recipient, amount/2);
        IHookCaller(hookCaller).executeTransfer(sender, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, amount/2);
    }
}