// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./erc777/ERC777Layer.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
//import "./interfaces/src20/ISRC20.sol";
//import "./Minimums.sol";

// contract T {
//     using SafeMath for uint256;
//     uint256 i;
//     uint256 i2;
//     function set() public {
//         uint256 j;
//         for (j = 0; j < 5; j = j.add(1)) {
//             i2 = j;
//         }    
//         i = j;
//     }
//     function get() public view returns(uint256,uint256) {
//         return (i,i2);
//     }
    
// }
// /*
//  * @title TransferRules contract
//  * @dev Contract that is checking if on-chain rules for token transfers are concluded.
//  */
contract Dividends is Ownable, ERC777Layer, IERC777Recipient {
    
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
	
    address _token;
    uint256 stakeDuration;
    
    // index stored when contract deployed
    uint256 startedIndexInterval;
    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    
    event Staked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    
    mapping(uint256 => uint256) totalShares;
    
    struct UPool {
        uint256 shares;
        //uint256 accomulatedDividendsForPeriod;
        //uint256 accomulatedDividendsTotal;
        uint256 exists;
    }
    
    struct User {
        mapping(uint256 => UPool) userPool;
        uint256 lastClaimRedeemTime;
    }
    mapping(address => User) users;
    
    
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 duration,
        address token
    ) 
        ERC777Layer(name_, symbol_, defaultOperators_)
    {
        
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        
        require(duration != 0, "wrong duration");
        stakeDuration = duration;
        _token = token;
        
        startedIndexInterval = getCurrentIndexInterval();
    }
    
// address a1;
// address a2;
// address a3;
// function get() public view returns(address,address,address) {
//     return (a1,a2,a3);
// }
    
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
        // a1 = operator;
        // a2 = from;
        // a3 = to;
        
        if (msg.sender == _token) {
            
            stake(from, amount);
            
        }
    }
    
    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        super._move(operator, from, to, amount, userData, operatorData);
        // store balances into buckets
        
        uint256 currentIndexInterval = getCurrentIndexInterval();
        if (from != address(0)) {
            users[from].userPool[currentIndexInterval].balance = balanceOf(from);
            users[from].userPool[currentIndexInterval].exists = 1;
        }
        if (to != address(0)) {
            uint256 i = currentIndexInterval;
            
            users[to].userPool[i].balance = balanceOf(to);
            users[to].userPool[i].exists = 1;
        }
        
        totalBalances[currentIndexInterval] = totalSupply();
    }
    
    function stake(
        address addr, 
        uint256 amount
    )
        internal
    {
        require(amount != 0, "wrong amount");
        
        _mint(addr, amount, "", "");
            
        emit Staked(addr, amount);
    }
    
    function calculateDividends(
        address addr
    )
        internal
    {
        // started 0
        // 0-0
        // 0-1
        uint256 currentIndexInterval = getCurrentIndexInterval();
        uint256 lastClaimRedeemTime = users[addr].lastClaimRedeemTime;
        if (currentIndexInterval > lastClaimRedeemTime) {
            uint256 i;
            
            uint256 balance;
            uint256 accomulatedDividendsForPeriod;
            uint256 accomulatedDividendsTotal;
            
            balance = users[addr].userPool[lastClaimRedeemTime].balance;
            accomulatedDividendsForPeriod = users[addr].userPool[lastClaimRedeemTime].accomulatedDividendsForPeriod;
            accomulatedDividendsTotal = users[addr].userPool[lastClaimRedeemTime].accomulatedDividendsTotal;
        
            for (i = lastClaimRedeemTime; i < currentIndexInterval; i = i.add(stakeDuration)) {
                if (users[addr].userPool[i].exists == 1) {
                    
                    
                    balance = users[addr].userPool[i].balance;
                    accomulatedDividendsForPeriod = users[addr].userPool[i].accomulatedDividendsForPeriod;
                    accomulatedDividendsTotal = users[addr].userPool[i].accomulatedDividendsTotal;
                }
                //users[addr].userPool[i].accomulatedDividendsForPeriod = 
            }
        }
    }
    /*
    mapping(uint256 => uint256) totalBalances;
    
    struct Pool {
        uint256 balance;
        uint256 accomulatedDividendsForPeriod;
        uint256 accomulatedDividendsTotal;
        uint256 exists;
    }
    
    struct User {
        mapping(uint256 => Pool) userPool;
        uint256 lastClaimRedeemTime;
        
    }
    mapping(address => User) users;
    */
    function getCurrentIndexInterval() internal view returns(uint256) {
        return (block.timestamp).div(stakeDuration).mul(stakeDuration);
    }
    
    function getNextIndexInterval() internal view returns(uint256) {
        return getCurrentIndexInterval().add(stakeDuration);
    }
    
    function claim()
        public
    {
        calculateDividends(_msgSender());
    }
    
    function redeem()
        public
    {
        calculateDividends(_msgSender());
    }
/*
    
    function claim()
        public
        override 
    {
        address addr =_msgSender();
        (uint256 retMinimum,) = getMinimum(addr);
        uint256 amount = balanceOf(_msgSender()).sub(retMinimum);
        
        require(amount != 0, "insufficient balance");
        
        uint256 lastClaimTime = lastClaimRedeemTime[addr];
        lastClaimRedeemTime[addr] = block.timestamp;
        
        // (amount able to redeem) * (seconds pass from last claim) / 1e10
        uint256 benefits = amount.mul(block.timestamp.sub(lastClaimTime)).div(1e10);
        
        require(benefits != 0, "insufficient balance");
        
        require(ISRC20(_src20).executeTransfer(address(this), addr, benefits), "SRC20 transfer failed");
        
        emit Claimed(addr, benefits);
    }
    
    function redeem()
        public
        override 
    {
        address addr =_msgSender();
        
        (uint256 retMinimum,) = getMinimum(addr);
        
        uint256 amount = balanceOf(addr).sub(retMinimum);
        require(amount != 0, "insufficient balance");
        _burn(addr, amount);

        require(ISRC20(_src20).executeTransfer(address(this), addr, amount), "SRC20 transfer failed");
        
        emit Redeemed(_msgSender(), amount);
    }
    
    function cleanSRC() public override onlyOwner() {
        _src20 = address(0);
    }
    
    function setSRC(address src20) public override onlyOwner() returns (bool) {
        _src20 = src20;
        
        return true;
    }
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        
        if (
            (sender == address(0)) && (recipient != address(0))
        ) {
            // mint
            minimumsAdd(recipient, amount, block.timestamp.add(stakeDuration), true);
        } else {
            // burn
            (uint256 retMinimum,) = getMinimum(sender);
            uint256 tmpAmount = balanceOf(sender).sub(retMinimum);
            require(tmpAmount >= amount, "insufficient balance");
            // burn or usual transfer
            minimumsTransfer(
                sender, 
                recipient, 
                amount, 
                false, 
                0
            );
        
        }
        
    }
    */
}