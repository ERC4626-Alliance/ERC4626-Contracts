// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MCT", 18) {}

    function mint(address account, uint256 amount) public returns (bool) {
        _mint(account, amount);
        return true;
    }

    function mockBurn(address account, uint256 amount) public returns (bool) {
        _burn(account, amount);
        return true;
    }

    function approveOverride(address owner, address spender, uint256 amount) public {
        allowance[owner][spender] = amount;
    }
}
