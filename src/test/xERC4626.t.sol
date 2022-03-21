// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockxERC4626} from "./mocks/MockxERC4626.sol";

contract xERC4626Test is DSTestPlus {
    MockxERC4626 xToken;
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("token", "TKN", 18);
        xToken = new MockxERC4626(token, "xToken", "xTKN", 1000);
        token.mint(address(this), 100e18);
        token.approve(address(xToken), 100e18);
    }

    /// @dev test totalAssets call before, during, and after a reward distribution that starts on cycle start
    function testTotalAssetsDuringRewardDistribution() public {
        // first seed pool with 50 tokens
        xToken.deposit(50e18, address(this));
        require(xToken.totalAssets() == 50e18, "seed");

        // mint another 100 tokens
        token.mint(address(xToken), 100e18);
        require(xToken.lastRewardAmount() == 0, "reward");
        require(xToken.totalAssets() == 50e18, "totalassets");
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        xToken.syncRewards();
        // after sync, everything same except lastRewardAmount
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 50e18);
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        // accrue half the rewards
        hevm.warp(500);
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 100e18);
        require(xToken.convertToShares(100e18) == 50e18); // 1:2 now

        // accrue remaining rewards
        hevm.warp(1000);
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 150e18);
        require(xToken.convertToShares(150e18) == 50e18); // 1:3 now

        // accrue all and warp ahead 1 cycle
        hevm.warp(2000);
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 150e18);
        require(xToken.convertToShares(150e18) == 50e18); // 1:3 now
    }

    /// @dev test totalAssets call before, during, and after a reward distribution that starts mid-cycle
    function testTotalAssetsDuringDelayedRewardDistribution() public {
        // first seed pool with 50 tokens
        xToken.deposit(50e18, address(this));
        require(xToken.totalAssets() == 50e18, "seed");

        // mint another 100 tokens
        token.mint(address(xToken), 100e18);
        require(xToken.lastRewardAmount() == 0, "reward");
        require(xToken.totalAssets() == 50e18, "totalassets");
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        hevm.warp(500); // start midway

        xToken.syncRewards();
        // after sync, everything same except lastRewardAmount
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 50e18);
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        // accrue half the rewards
        hevm.warp(750);
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 100e18);
        require(xToken.convertToShares(100e18) == 50e18); // 1:2 now

        // accrue remaining rewards
        hevm.warp(1000);
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 150e18);
        require(xToken.convertToShares(150e18) == 50e18); // 1:3 now

        // accrue all and warp ahead 1 cycle
        hevm.warp(2000);
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 150e18);
        require(xToken.convertToShares(150e18) == 50e18); // 1:3 now
    }

    function testTotalAssetsAfterDeposit() public {
        xToken.deposit(10e18, address(this));
        require(xToken.totalAssets() == 10e18);

        xToken.deposit(40e18, address(this));
        require(xToken.totalAssets() == 50e18);
    }

    function testTotalAssetsAfterWithdraw() public {
        xToken.deposit(50e18, address(this));
        require(xToken.totalAssets() == 50e18);

        xToken.withdraw(40e18, address(this), address(this));
        require(xToken.totalAssets() == 10e18);
    }

    function testSyncRewardsFailsDuringCycle() public {
        xToken.deposit(50e18, address(this));
        token.mint(address(xToken), 100e18);
        xToken.syncRewards();
        hevm.expectRevert(abi.encodeWithSignature("SyncError()"));
        xToken.syncRewards();
    }

    function testSyncRewardsAfterEmptyCycle() public {
        // first seed pool with 50 tokens
        xToken.deposit(50e18, address(this));
        require(xToken.totalAssets() == 50e18, "seed");
        hevm.warp(100);

        // sync with no new rewards
        xToken.syncRewards();
        require(xToken.lastRewardAmount() == 0);  
        require(xToken.lastSync() == 100);  
        require(xToken.rewardsCycleEnd() == 1000);  
        require(xToken.totalAssets() == 50e18);
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        // fast forward to next cycle and add rewards
        hevm.warp(1000);
        token.mint(address(xToken), 100e18); // seed new rewards

        xToken.syncRewards();
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 50e18);
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        hevm.warp(2000);

        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.totalAssets() == 150e18);
        require(xToken.convertToShares(150e18) == 50e18); // 3:1 now
    }

    function testSyncRewardsAfterFullCycle() public {
        // first seed pool with 50 tokens
        xToken.deposit(50e18, address(this));
        require(xToken.totalAssets() == 50e18, "seed");
        hevm.warp(100);
        token.mint(address(xToken), 100e18); // seed new rewards
        // sync with new rewards
        xToken.syncRewards();
        require(xToken.lastRewardAmount() == 100e18);  
        require(xToken.lastSync() == 100);  
        require(xToken.rewardsCycleEnd() == 1000);  
        require(xToken.totalAssets() == 50e18);
        require(xToken.convertToShares(50e18) == 50e18); // 1:1 still

        // fast forward to next cycle and add rewards
        hevm.warp(1000);
        token.mint(address(xToken), 250e18); // seed new rewards

        xToken.syncRewards();
        require(xToken.lastRewardAmount() == 250e18);  
        require(xToken.totalAssets() == 150e18);
        require(xToken.convertToShares(150e18) == 50e18); // 3:1 now

        hevm.warp(2000);

        require(xToken.lastRewardAmount() == 250e18);  
        require(xToken.totalAssets() == 400e18);
        require(xToken.convertToShares(400e18) == 50e18); // 8:1 now
    }
}