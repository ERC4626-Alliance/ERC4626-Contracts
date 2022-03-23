// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockxERC4626} from "../mocks/MockxERC4626.sol";

contract xERC4626Test is DSTestPlus {
    MockERC20 token;
    MockxERC4626 xToken;
    function setUp() public {
        token = new MockERC20("token", "TKN", 18);
        xToken = new MockxERC4626(token, "xToken", "xTKN", 1000);
    }

    function invariant_totalAssets() public {
        require(xToken.totalAssets() <= token.balanceOf(address(xToken)));
    }

    function invariant_convert() public {
        require(xToken.convertToShares(xToken.totalAssets()) == xToken.totalSupply());
        require(xToken.convertToAssets(xToken.totalSupply()) == xToken.totalAssets());
    }

    function invariant_increase() public {
        uint256 previousTotal = xToken.totalAssets();
        hevm.warp(block.timestamp + 100);
        require(xToken.totalAssets() >= previousTotal);
    }

    function invariant_cycleEnd() public {
        hevm.warp(xToken.rewardsCycleEnd());
        xToken.syncRewards();
        hevm.warp(xToken.rewardsCycleEnd());
        require(xToken.totalAssets() == token.balanceOf(address(xToken)));
    }
}
