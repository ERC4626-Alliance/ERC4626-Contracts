// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20, xERC4626, ERC4626} from "../../xERC4626.sol";

import {Hevm} from "solmate/test/utils/Hevm.sol";

interface Mintable {
    function mint(address,uint) external;
}

contract MockxERC4626 is xERC4626 {
    Hevm internal constant hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol,
        uint32 _rewardsCycleLength
    ) ERC4626(_underlying, _name, _symbol) xERC4626(_rewardsCycleLength) {}

    function warpInCycle(uint256 warp) public {
        hevm.warp(warp % rewardsCycleLength);
    }

    function reward(uint256 amount) public {
        Mintable(address(asset)).mint(address(this), amount);
    }
}
