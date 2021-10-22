// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DividendsContractUNI.sol";

contract DividendsContractUNIMock is DividendsContractUNI {
    
    
    
    function getITR() internal view override returns(address) {
        // pair  0x9B3562FC21Dcd3e083ae82480A14C9672E56b794
        // token 0xD2091C85C0512EC1dF960eeE021Cc887CB4D65B1
        // weth  0xc778417E063141139Fce010982780140Aa0cD5Ab
        return 0xD2091C85C0512EC1dF960eeE021Cc887CB4D65B1;
    }
    
    function mint(address account, uint256 amount) public virtual {
        _mint(account, amount, "", "");
    }
    
    function minimumsView(
        address addr
    ) 
        public 
        view
        returns (uint256)
    {
        return _getMinimum(addr);
    }
    
    function getCurrentInterval() public view returns(uint256) {
        return getIndexInterval(block.timestamp);
    }
}