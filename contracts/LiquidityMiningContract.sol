// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';


import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777SenderUpgradeable.sol";

import "./erc777/ERC777LayerUpgradeable.sol";


// import "./lib/SumLibrary.sol";
// import "./interfaces/IDividendsContract.sol";

import "./minimums/upgradeable/MinimumsBase.sol";

import "./interfaces/ILiquidityMiningContract.sol";

contract LiquidityMiningContract is OwnableUpgradeable, ERC777LayerUpgradeable, IERC777RecipientUpgradeable, IERC777SenderUpgradeable, MinimumsBase, ILiquidityMiningContract {
    using SafeMathUpgradeable for uint256;
    
    uint256 lockupDuration;
    
    event Staked(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    address factory;
    address public token0;
    address public token1;
   
   
    constructor() {
        factory = msg.sender;
    }
    
    // called once by the factory at time of deployment
    function initialize(
        address _token0, 
        address _token1,
        uint256 lockupInterval_, //  interval 
        uint256 lockupDuration_
    )
    
        initializer
        external 
        override
    {
        require(msg.sender == factory, 'LiquidityMiningERC777: FORBIDDEN'); // sufficient check
        
        
        token0 = _token0;
        token1 = _token1;
        __Ownable_init();
        __ERC777LayerUpgradeable_init("Liquidity Mining Tokens","LMT",(new address[](0)));
        MinimumsBase_init(lockupInterval_);
        
        lockupDuration = lockupDuration_;
    }
   /* 
    constructor(
        uint256 lockupInterval_, //  interval 
        uint256 lockupDuration_
    ) 
//    ERC777Layer(name_,symbol_,defaultOperators_)
//    MinimumsBase(lockupInterval_)
    {
        UniswapV2Router02 = IUniswapV2Router02(uniswapRouter);
        WETH = UniswapV2Router02.WETH();
        lockupDuration = lockupDuration_;
    }
    */
    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )   override
        virtual
        external
    {
    }
    
    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) 
        override
        virtual
        external
    {
        // a1 = operator;
        // a2 = from;
        // a3 = to;
        
        // msg.sender here is tokencontract that send from
        
        // if (msg.sender == token) {
            
        //     _stake(from, amount);
            
        // } else if (whitelist.contains(msg.sender)) {

        //     // save dividends
        //     _disburse(msg.sender, amount);
        // } else {
        //     revert("unsupported tokens");
        // }
        
    }
   
   
    function stake(address addr, uint256 amount) external override onlyOwner() {
        _stake(addr, amount);
    }
    
    function getMinimum(address addr) external view override returns(uint256) {
        return _getMinimum(addr);
    }
    
    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    
    
    function _stake(address addr, uint256 amount) internal {
        _mint(addr, amount, "", "");
        emit Staked(addr, amount);
        _minimumsAdd(addr, amount, lockupDuration, false);
        
    }
    
    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        
        
        
        if (from == address(0) || to == address(0)) {
            // todo 0: remove?
            // from == address(0) - is unreacheble, 
            // to == address(0) - only if user manually set recipient
            
        } else {
            
            // balance = 100             
            // locked 80
            // amount = 70
            // leftAmount = balance - amount = 100-70 = 30;
            // if (locked > leftAmount) {
            //     transfer is =  locked-leftAmount = 80-30 = 50
            // }
            // means that we use use unlocked first (20) and then that left (50). it's 50 we transfer as minimums to other

            uint256 balance = balanceOf(_msgSender());
            uint256 locked = _getMinimum(_msgSender());
            
            uint256 leftAmount = balance.sub(amount);
            if (locked > leftAmount) {
                minimumsTransfer(from, to, locked.sub(leftAmount));
            }
            
        }
        
        
        super._move(operator, from, to, amount, userData, operatorData);
    }
  
    
}