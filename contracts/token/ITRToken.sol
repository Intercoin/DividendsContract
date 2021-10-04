// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../erc777/ERC777Layer.sol";
import "../interfaces/IHook.sol";
import "../interfaces/IHookCaller.sol";

contract ITRToken is Ownable, ERC777Layer, IHookCaller {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    
    address public transferHook;
    EnumerableSet.AddressSet authorityList;
    
    modifier onlyAuthority() {
        require(authorityList.contains(_msgSender()) == true, "Access denied");
        _;
    }
    
    /**
     * @dev `defaultOperators` may be an empty array.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 initialSupply,
        address owner
    
    ) 
        ERC777Layer(name_, symbol_, defaultOperators_)
    {

        _mint(owner, initialSupply, "", "");
    }


    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        if (transferHook != address(0)) {
            IHook(transferHook).doTransfer(operator, from, to, amount, userData, operatorData);
        } else {
            super._move(operator, from, to, amount, userData, operatorData);
        }
        
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
        address operator, 
        address from, 
        address to, 
        uint256 amount, 
        bytes memory userData, 
        bytes memory operatorData
    ) 
        external 
        override
        onlyAuthority() 
    {
        super._move(operator, from, to, amount, userData, operatorData);
        _callTokensReceived(operator, from, to, amount, userData, operatorData, false);
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
    
    
    function bulkTransfer(address[] memory _recipients, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _recipients.length; i++) {
            super._move(_msgSender(), _msgSender(), _recipients[i], _amounts[i], "", "");
        }
    }
    
    function mintAndStake(address stakeContract, address[] memory _recipients, uint256[] memory _amounts) public onlyOwner() {
        for (uint256 i = 0; i < _recipients.length; i++) {
            // __move(_msgSender(), _msgSender(), _recipients[i], _amounts[i], "", "");     // from sender to recipient
            // __move(_msgSender(), _recipients[i], stakeContract, _amounts[i], "", "");    // from recipient to stake contract
            
            super._move(_msgSender(), _msgSender(), stakeContract, _amounts[i], "", "");
            _callTokensReceived(_msgSender(), _recipients[i], stakeContract, _amounts[i], "", "", true);
        }
    }
    
         
}