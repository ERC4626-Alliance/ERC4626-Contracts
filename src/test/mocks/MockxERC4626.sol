// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20, xERC4626, ERC4626} from "../../xERC4626.sol";

contract MockxERC4626 is xERC4626 {
    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol,
        uint32 _rewardsCycleLength
    ) ERC4626(_underlying, _name, _symbol) xERC4626(_rewardsCycleLength) {}
}
