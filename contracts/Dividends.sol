// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

//import "./interfaces/IDividends.sol";
//import "./interfaces/src20/ISRC20.sol";
//import "./Minimums.sol";

// /*
//  * @title TransferRules contract
//  * @dev Contract that is checking if on-chain rules for token transfers are concluded.
//  */
contract Dividends is Ownable, ERC777, IERC777Recipient {
    
	using SafeMath for uint256;
	//using MathUpgradeable for uint256;
    
    mapping(address => uint256) lastClaimRedeemTime;
    address _token;
    uint256 stakeDuration;
    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    
    event Staked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 duration,
        address token
    
    ) 
        ERC777(name_, symbol_, defaultOperators_)
    {
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        
        require(duration != 0, "wrong duration");
        stakeDuration = duration;
        _token = token;
    }

address a1;
address a2;
address a3;
function get() public view returns(address,address,address) {
    return (a1,a2,a3);
}
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) 
        override
        external
    {
        a1 = operator;
        a2 = from;
        a3 = to;
        
        if (msg.sender == _token) {
            
            stake(from, amount);
            
        }
    }

    function stake(
        address addr, 
        uint256 amount
    )
        internal
    {
        require(amount != 0, "wrong amount");
        
        if (lastClaimRedeemTime[addr] == 0) {
            lastClaimRedeemTime[addr] = block.timestamp;
        }
        
        _mint(addr, amount, "", "");
            
        emit Staked(addr, amount);
    }
    
/*
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
    */
}