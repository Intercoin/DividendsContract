// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DividendsContract.sol";

import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract DividendsContractUNI is DividendsContract {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    //address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    address internal constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant uniswapRouterFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    address internal WETH;
    address public token0;
    address public token1;
    bool public wethMode;
    
    /**
     * init internal
     * @param token_ // Token from Pair -  ITR-[Token]
     */
     function initialize(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        uint256 interval_, // * interval: WEEK by default
        uint256 duration_, // * duration: 52 (intervals)
        uint256 multiplier_,
        address token_, 
        address[] memory whitelist_
    ) 
        public 
        virtual
        initializer
        override
    {
        
        //LPTokens( IUniswapV2Factory.getPair)
        
        address pair = __DividendsContractUNI_init(token_);
        
        __DividendsBase_init(name_, symbol_, defaultOperators_, interval_, duration_, multiplier_, pair, whitelist_);
        
        
    }
    
    function addLiquidityAndStakeCoin() public payable {
        require(wethMode == true, "Pair need to contain WETH token");
        
        uint256 amountETH = msg.value;
        IWETH(WETH).deposit{value: amountETH}();
        
        addLiquidityAndStake(_msgSender(), WETH, amountETH);
        
    }
    
    function addLiquidityAndStakeToken(address token_, uint256 amount_) public {
        
        require(token_ == token1, "Pair need to contain token");
        
        bool success = IERC20Upgradeable(token_).transferFrom(_msgSender(), address(this), amount_);
        require(success == true, "");
        
        addLiquidityAndStake(_msgSender(), token_, amount_);
        
    }
    receive() external payable {
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
        
        external
    {
        if (
            msg.sender == WETH ||
            msg.sender == token0 ||
            msg.sender == token1 ||
            msg.sender == token
        ) {
            
        } else {
            if (msg.sender == token) {
            
                _stake(from, amount);
            
            } else if (whitelist.contains(msg.sender)) {
    
                // save dividends
                _disburse(msg.sender, amount);
            } else {
                revert("unsupported tokens");
            }
        // a1 = operator;
        // a2 = from;
        // a3 = to;
        
        // msg.sender here is tokencontract that send from
        
        
        }
    }

    /**
     * @param token_ // Token from Pair -  ITR-[Token]
     * 
     */
    function __DividendsContractUNI_init(
        address token_ 
    ) 
        internal
        initializer 
        returns(address pair)
    {
        
        WETH = IUniswapV2Router02(uniswapRouter).WETH();
        
        pair =  IUniswapV2Factory(uniswapRouterFactory).getPair(getITR(), token_);
        
        require (pair != address(0), "could not find pair with ITR");
        
        token0 = IUniswapV2Pair(pair).token0();
        token1 = IUniswapV2Pair(pair).token1();

        // make token0 is ITR
        if (token1 == getITR()) {
            (token0, token1) = (token1, token0);
        }

        if (token1 == WETH) {
            wethMode = true;
        }
        
    }
    
    function addLiquidityAndStake(address from, address token_, uint256 amount_) internal {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(token).getReserves();
        
        // (r0+x)*r1/r0-r1
        uint256 itrAmount = ((reserve0.add(amount_)).mul(reserve1).div(reserve0)).sub(reserve1);
            
        //if (token0 == ITR) {
            // (r0+x)*r1/r0-r1
            // itrAmount = ((reserve0.add(amount)).mul(reserve1).div(reserve0)).sub(reserve1);
        //} else {
            // (r1+x)*r0/r1-r0
            // itrAmount = ((reserve1.add(amount)).mul(reserve0).div(reserve1)).sub(reserve0);
        //}
        require (itrAmount > 0, "itrAmount is not enough need > 0" );
        bool success;
        
        success = IERC20Upgradeable(getITR()).approve(uniswapRouter, itrAmount);
        require(success == true, "");
        
        success = IERC20Upgradeable(token_).approve(uniswapRouter, amount_);
        require(success == true, "");
        
        (,, uint256 lpTokens) = _uniswapV2Router.addLiquidity(
            getITR(),
            token_,
            itrAmount,
            amount_,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        require (lpTokens > 0, "lpTokens need > 0" );
        _stake(from, lpTokens);
        
    }
    
    function getITR() internal view virtual returns(address) {
        ///address public constant ITR = 0x6Ef5febbD2A56FAb23f18a69d3fB9F4E2A70440B;
        return 0x6Ef5febbD2A56FAb23f18a69d3fB9F4E2A70440B;
    }
}
    

 
    
    
    
    