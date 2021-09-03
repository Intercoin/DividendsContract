// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./interfaces/IDividends.sol";
import "./interfaces/src20/ISRC20.sol";
import "./Minimums.sol";

// /*
//  * @title TransferRules contract
//  * @dev Contract that is checking if on-chain rules for token transfers are concluded.
//  */
contract Dividends is OwnableUpgradeable, ERC20Upgradeable, IDividends, Minimums {
    
	using SafeMathUpgradeable for uint256;
	//using MathUpgradeable for uint256;
    
    mapping(address => uint256) lastClaimRedeemTime;
    address _src20;
    uint256 stakeDuration;
    
    event Staked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    function initialize(
        string memory name, 
        string memory symbol, 
        uint256 duration,
        address src20
    )  
        external 
        override
        initializer 
    {
        __Ownable_init();
        __ERC20_init(name, symbol);
        __Dividends_init(duration, src20);
    }
    
    function __Dividends_init(
        uint256 duration,
        address src20
    )
        internal
        initializer 
    {
        require(duration != 0, "wrong duration");
        stakeDuration = duration;
        _src20 = src20;
    }
function TTT(address addr, uint256 amount) public { _mint(addr, amount);}    

    function stake(
        address addr, 
        uint256 amount
    )
        external 
        override 
        onlyOwner()
    {
        if (lastClaimRedeemTime[addr] == 0) {
            lastClaimRedeemTime[addr] = block.timestamp;
        }
        
        require(amount != 0, "wrong amount");
        
        _mint(addr, amount);
        emit Staked(addr, amount);
    }
    
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
}