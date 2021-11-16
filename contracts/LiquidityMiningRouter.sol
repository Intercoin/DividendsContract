// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import "./erc777/ERC777Layer.sol";
import "./interfaces/ILiquidityMiningFactory.sol";
import "./interfaces/ILiquidityMiningContract.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract LiquidityMiningRouter is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    address internal constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant uniswapRouterFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal WETH;

    IUniswapV2Router02 internal UniswapV2Router02;
    
    uint256 lockupDuration;
    event rewardGranted(address indexed token, address indexed account, uint256 amount);
    event Staked(address indexed lpPair, address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    
    address public factory;
    
    uint256 public reserveClaimFraction;
    uint256 public tradedClaimFraction;
    uint256 internal constant MULTIPLIER = 100000;
    
    EnumerableSet.AddressSet private rewardTokensList;
    //address token0;
    //address token1;
    
    
    receive() external payable {
    }
    
    
    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    
    constructor(address factory_, uint256 tradedClaimFraction_, uint256 reserveClaimFraction_) {
        
        require(factory_ != address(0), "wrong factory address");
        require(tradedClaimFraction_ <= MULTIPLIER, "wrong tradedClaimFraction");
        require(reserveClaimFraction_ <= MULTIPLIER, "wrong reserveClaimFraction");
        
        factory = factory_; 
        //WETH = _WETH;
        tradedClaimFraction = tradedClaimFraction_;
        reserveClaimFraction = reserveClaimFraction_;
        
        UniswapV2Router02 = IUniswapV2Router02(uniswapRouter);
        
    }
    
    function addLiquidityAndStake(address tradedToken, address reserveToken, uint256 lockupPeriod) public payable {
        
        require(msg.value>0, "insufficient balance");
        
        uint256 amountETH = msg.value;
        IWETH(WETH).deposit{value: amountETH}();
        
        uint256 amountReverveToken = uniswapExchange(WETH, reserveToken, amountETH);
            
        _addLiquidityAndStake(msg.sender, tradedToken, reserveToken, amountReverveToken, lockupPeriod);
        
    }
    
    function addLiquidityAndStake(address tradedToken, address reserveToken, address payingToken, uint256 amount, uint256 lockupPeriod) public {
        
        require(IERC20(payingToken).transferFrom(msg.sender, address(this), amount), 'transferFrom failed.');
        
        uint256 amountReverveToken = uniswapExchange(payingToken, reserveToken, amount);
            
        _addLiquidityAndStake(msg.sender, tradedToken, reserveToken, amountReverveToken, lockupPeriod);
    }
    
    function addLiquidityAndStake(address tradedToken, address reserveToken, uint256 amount, uint256 lockupPeriod) public {
        
        require(IERC20(reserveToken).transferFrom(msg.sender, address(this), amount), 'transferFrom failed.');
        _addLiquidityAndStake(msg.sender, tradedToken, reserveToken, amount, lockupPeriod);
    }
    
    function redeemAndRemoveLiquidity(address sharesPair, uint256 amount) public {
        
        require(IERC20(sharesPair).transferFrom(msg.sender, address(this), amount), 'transferFrom failed.');
        
        (address token0, address token1) = ILiquidityMiningFactory(factory).tokensByPair(sharesPair);
        require(token0 != address(0) && token1 != address(0), "Can not find such sharesPair");
        
        uint256 amount2RedeemTotal = getRedeemAmount(sharesPair, msg.sender);
        require(amount2RedeemTotal >= amount, "insufficient amount to redeem");
        uint256 amount2Redeem = amount;
            
        //IERC20Upgradeable(token).transfer(_msgSender(), amount2Redeem);
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        
        address uniswapPair =  IUniswapV2Factory(uniswapRouterFactory).getPair(token0, token1);
        require(uniswapPair != address(0), "Pair could not exist");
        
        require(IERC20(uniswapPair).approve(uniswapRouter, amount2Redeem), 'approve failed.');
        
        (uint amountA, uint amountB) = UniswapV2Router02.removeLiquidity(
            token0,//address tokenA,
            token1,//address tokenB,
            amount2Redeem,//uint liquidity,
            0,//uint amountAMin,
            0,//uint amountBMin,
            address(this),//address to,
            block.timestamp//uint deadline
        );
        
        
        adjustedAmount(token0, amountA, tradedClaimFraction, owner(), _msgSender());
        adjustedAmount(token1, amountB, reserveClaimFraction, owner(), _msgSender());
        
        grantReward(sharesPair, _msgSender());
        
        emit Redeemed(_msgSender(), amount2Redeem);
        //_burn(_msgSender(), amount2Redeem, "", "");
        IERC20(sharesPair).transfer(deadAddress, amount2Redeem);
        
        //(users[_msgSender()].balances).add(balanceOf(_msgSender()));
    
    
    }
    
    function addRewardToken(address addr) public onlyOwner() {
        rewardTokensList.add(addr);
    }
    function removeRewardToken(address addr) public onlyOwner() {
        rewardTokensList.remove(addr);
    }
    function viewRewardTokensList() public view returns(address[] memory) {
        return rewardTokensList.values();
    }
    
    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    
    /**
     * when user redeem token we will additionally grant percent of
     * token's reward by formula
     * usershares/totalShares * Whitelisttoken[X]
    */
    function grantReward(address sharesPair_, address to) internal {
        uint256 multiplier = 1_000_000_000;
        uint256 ratio = multiplier.
            mul(
                IERC20(sharesPair_).balanceOf(to)
            ).
            div(
                IERC20(sharesPair_).totalSupply()
            )
            ;
            
        uint256 reward2Send;
        if (ratio > 0) {
            for (uint256 i=0; i<rewardTokensList.length(); i++) {
                reward2Send = IERC20(rewardTokensList.at(i)).balanceOf(address(this)).mul(ratio).div(multiplier);
                if (reward2Send > 0) {
                    IERC20(rewardTokensList.at(i)).transfer(to, reward2Send);
                    emit rewardGranted(rewardTokensList.at(i), to, reward2Send);
                }
            }
        }
    }
    
    function adjustedAmount(address token_, uint256 amount_, uint256 fraction_, address fractionAddr_, address to_) internal {
        if (fraction_ == MULTIPLIER) {
            IERC20(token_).transfer(fractionAddr_, amount_);
        } else if (fraction_ == 0) {
            IERC20(token_).transfer(to_, amount_);
        } else {
            uint256 adjusted = amount_.mul(fraction_).div(MULTIPLIER);
            IERC20(token_).transfer(fractionAddr_, adjusted);
            IERC20(token_).transfer(to_, amount_.sub(adjusted));
        }
    }
    
    function getRedeemAmount(address lmpair_, address addr_) internal view returns(uint256 amount2Redeem) {
        
        uint256 balance = IERC20(lmpair_).balanceOf(addr_);
        uint256 locked = ILiquidityMiningContract(lmpair_).getMinimum(addr_);
        
        require(balance > locked, "Nothing to redeem");
        amount2Redeem = balance.sub(locked);
    }
    
    function uniswapExchange(address tokenIn, address tokenOut, uint256 amountIn) internal returns(uint256 amountOut) {
        require(IERC20(tokenIn).approve(address(uniswapRouter), amountIn), 'approve failed.');
        // amountOutMin must be retrieved from an oracle of some kind
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);
        uint256[] memory outputAmounts = UniswapV2Router02.swapExactTokensForTokens(amountIn, 0/*amountOutMin*/, path, address(this), block.timestamp);
        amountOut = outputAmounts[1];
    }
    
    function _addLiquidityAndStake(address from, address token0, address token1, uint256 amountToken1, uint256 lockupPeriod) internal {

        address pair =  IUniswapV2Factory(uniswapRouterFactory).getPair(token0, token1);
        require(pair != address(0), "Pair could not exist");
        
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        require (reserve0 != 0 && reserve1 != 0, "empty reserves");
        
        
        //Then the amount they would want to swap is
        // r3 = sqrt( (r1 + r2) * r1 ) - r1
        // where 
        //  r1 - reserve at uniswap(reserve1)
        //  r2 - incoming reserver token (amountToken1)
        uint256 r3 = sqrt( (reserve1.add(amountToken1)).mul(reserve1)).sub(reserve1); //    
        require(r3>0, "r3>0");
        require(amountToken1.sub(r3)>0, "amountToken1.sub(r3)>0");


        // left (amountToken1-r3) we will exchange at uniswap to traded token
        
        uint256 amountToken0 = uniswapExchange(token1, token0, amountToken1.sub(r3));

        require(IERC20(token1).approve(uniswapRouter, r3), 'approve failed.');
        require(IERC20(token0).approve(uniswapRouter, amountToken0), 'approve failed.');

        (,, uint256 lpTokens) = UniswapV2Router02.addLiquidity(
            token0,
            token1,
            amountToken0,
            r3,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        // -------------------------------------------------------------------------------------------
        //    old logic: here we keep current price and get amountToken0 as already predifined(donated)
        // (r0+x)*r1/r0-r1
        //uint256 amountToken0 = ((reserve0.add(amountToken1)).mul(reserve1).div(reserve0)).sub(reserve1);
        // uint256 amountToken0;
        // if (token0 == IUniswapV2Pair(pair).token0()) {
        //     //(r0+x)*r1/r0-r1
        //     amountToken0 = ((reserve0.add(amountToken1)).mul(reserve1).div(reserve0)).sub(reserve1);
        // } else {
        //     //(r1+x)*r0/r1-r0
        //     amountToken0 = ((reserve1.add(amountToken1)).mul(reserve0).div(reserve1)).sub(reserve0);
        // }
        // require(amountToken0 > 0 && IERC20(token0).balanceOf(address(this))>=amountToken0, "tradedToken is not enough." );
        // require(IERC20(token1).approve(uniswapRouter, amountToken1), 'approve failed.');
        // require(IERC20(token0).approve(uniswapRouter, amountToken0), 'approve failed.');
        // (,, uint256 lpTokens) = UniswapV2Router02.addLiquidity(
        //     token0,
        //     token1,
        //     amountToken0,
        //     amountToken1,
        //     0, // slippage is unavoidable
        //     0, // slippage is unavoidable
        //     address(this),
        //     block.timestamp
        // );
        // -------------------------------------------------------------------------------------------
   
        require (lpTokens > 0, "lpTokens need > 0" );
        
        // create pair if not exist
        address lmpair = ILiquidityMiningFactory(factory).getPair(token0, token1, lockupPeriod);
        if (lmpair == address(0)) {
            lmpair = ILiquidityMiningFactory(factory).createPair(token0, token1, lockupPeriod);
        }
        // stake tokens
        ILiquidityMiningFactory(factory).stake(lmpair, from, lpTokens);

        emit Staked(lmpair, from, lpTokens);

    }
    
    
    function sqrt(uint256 x) private pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }
    
        // Calculate the square root of the perfect square of a power of two that is the closest to x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }
    
        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

}
