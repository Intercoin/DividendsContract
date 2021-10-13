// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC777Mintable is ERC777Upgradeable {
    
    /**
     */
    constructor (
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) 
    {
        __ERC777_init(name_, symbol_, defaultOperators_);
    }
    
    /**
     * @dev Creates `amount` tokens and send to account.
     *
     * See {ERC20-_mint}.
     */
    function mint(address account, uint256 amount) public virtual {
        _mint(account, amount, "", "");
    }
    
}