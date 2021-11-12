// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import "./erc777/ERC777Layer.sol";
import "./interfaces/ILiquidityMiningFactory.sol";
import "./LiquidityMiningContract.sol";

contract LiquidityMiningFactory is ILiquidityMiningFactory {
    uint256 lockupInterval = 24*60*60; // day in seconds
    uint256 lockupDuration = 365; // duration of intervals = 365 intervals(days)
        
    //create LiquidityMiningERC777 and become an owner
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    
    mapping(address => address) private pairCreator;
    
    struct Pair {
        address token0;
        address token1;
    }
    mapping(address => Pair) private pairTokens;
    //constructor() {}
    
    modifier onlyPairCreator(address pair) {
        require(pairCreator[pair] == msg.sender, "only for creator's pair");
        _;
    }
    
    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'LiquidityMiningFactory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'LiquidityMiningFactory: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'LiquidityMiningFactory: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(LiquidityMiningContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        LiquidityMiningContract(pair).initialize(token0, token1, lockupInterval, lockupDuration);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        pairCreator[pair] = msg.sender;
        
        pairTokens[pair].token0 = token0;
        pairTokens[pair].token1 = token1;
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
    function stake(address pair, address to, uint256 amount) public override onlyPairCreator(pair) {
        LiquidityMiningContract(pair).stake(to, amount);
    }
    
    function tokensByPair(address pair) public view override returns(address, address) {
        return (pairTokens[pair].token0, pairTokens[pair].token1);
    }
}
