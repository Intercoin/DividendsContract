// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IHook.sol";
import "./interfaces/IHookCaller.sol";


contract Token is Ownable, ERC20, IHookCaller {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address public transferHook;
    EnumerableSet.AddressSet authorityList;
    
    modifier onlyAuthority() {
        require(authorityList.contains(_msgSender()) == true, "Access denied");
        _;
    }
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
    
    function setTransferHook(address hook) public onlyOwner() {
        IHook(hook).doSetup();
        transferHook = hook;
        _addAuthority(hook);
    }
    
    function removeTransferHook() public onlyOwner() {
        _removeAuthority(transferHook);
        transferHook = address(0);
    }

    function addAuthority(address addr) public  onlyOwner() {
        _addAuthority(addr);
    }
    function removeAuthority(address addr) public  onlyOwner() {
        _removeAuthority(addr);
    }

    function executeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) 
        external 
        override
        onlyAuthority() 
    {
        super._transfer(sender, recipient, amount);
    }
    
    function _addAuthority(
        address addr
    ) 
        internal 
    {
        authorityList.add(addr);
    }
    
    function _removeAuthority(
        address addr
    ) 
        internal 
    {
        authorityList.remove(addr);
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) 
        internal 
        override 
    {
        if (transferHook != address(0)) {
            IHook(transferHook).doTransfer(sender, recipient, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}