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
    }

    /// @dev test totalAssets call before, during, and after a reward distribution that starts on cycle start
    function testTotalAssetsDuringRewardDistribution(uint128 seed, uint128 reward) public {
        uint256 combined = uint256(seed) + uint256(reward);

        unchecked {
            hevm.assume(seed != 0 && reward !=0 && combined < type(uint128).max);
        }

        token.mint(address(this), combined);
        token.approve(address(xToken), combined);

        // first seed pool
        xToken.deposit(seed, address(this));
        require(xToken.totalAssets() == seed, "seed");

        // mint rewards to pool
        token.mint(address(xToken), reward);
        require(xToken.lastRewardAmount() == 0, "reward");
        require(xToken.totalAssets() == seed, "totalassets");
        require(xToken.convertToAssets(seed) == seed); // 1:1 still

        xToken.syncRewards();
        // after sync, everything same except lastRewardAmount
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == seed);
        require(xToken.convertToAssets(seed) == seed); // 1:1 still

        // // accrue half the rewards
        hevm.warp(500);
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == uint256(seed) + (reward / 2));
        require(xToken.convertToAssets(seed) == uint256(seed) + (reward / 2)); // half rewards added
        require(xToken.convertToShares(uint256(seed) + (reward / 2)) == seed); // half rewards added

        // // accrue remaining rewards
        hevm.warp(1000);
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == combined);
        assertEq(xToken.convertToAssets(seed), combined); // all rewards added
        assertEq(xToken.convertToShares(combined), seed);

        // accrue all and warp ahead 1 cycle
        hevm.warp(2000);
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == combined);
        assertEq(xToken.convertToAssets(seed), combined); // all rewards added
        assertEq(xToken.convertToShares(combined), seed);
    }

    /// @dev test totalAssets call before, during, and after a reward distribution that starts on cycle start
    function testTotalAssetsDuringDelayedRewardDistribution(uint128 seed, uint128 reward) public {
        uint256 combined = uint256(seed) + uint256(reward);

        unchecked {
            hevm.assume(seed != 0 && reward !=0 && combined < type(uint128).max);
        }

        token.mint(address(this), combined);
        token.approve(address(xToken), combined);

        // first seed pool
        xToken.deposit(seed, address(this));
        require(xToken.totalAssets() == seed, "seed");

        // mint rewards to pool
        token.mint(address(xToken), reward);
        require(xToken.lastRewardAmount() == 0, "reward");
        require(xToken.totalAssets() == seed, "totalassets");
        require(xToken.convertToAssets(seed) == seed); // 1:1 still

        hevm.warp(500); // start midway

        xToken.syncRewards();
        require(xToken.lastRewardAmount() == reward, "reward");
        require(xToken.totalAssets() == seed, "totalassets");
        require(xToken.convertToAssets(seed) == seed); // 1:1 still

        // accrue half the rewards
        hevm.warp(750);
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == uint256(seed) + (reward / 2));
        require(xToken.convertToAssets(seed) == uint256(seed) + (reward / 2)); // half rewards added

        // accrue remaining rewards
        hevm.warp(1000);
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == combined);
        assertEq(xToken.convertToAssets(seed), combined); // all rewards added
        assertEq(xToken.convertToShares(combined), seed);

        // accrue all and warp ahead 1 cycle
        hevm.warp(2000);
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == combined);
        assertEq(xToken.convertToAssets(seed), combined); // all rewards added
        assertEq(xToken.convertToShares(combined), seed);
    }

    function testTotalAssetsAfterDeposit(uint128 deposit1, uint128 deposit2) public {
        hevm.assume(deposit1 != 0 && deposit2 !=0);

        uint256 combined = uint256(deposit1) + uint256(deposit2);
        token.mint(address(this), combined);
        token.approve(address(xToken), combined);
        xToken.deposit(deposit1, address(this));
        require(xToken.totalAssets() == deposit1);

        xToken.deposit(deposit2, address(this));
        assertEq(xToken.totalAssets(), combined);
    }

    function testTotalAssetsAfterWithdraw(uint128 deposit, uint128 withdraw) public {
        
        hevm.assume(deposit != 0 && withdraw != 0 && withdraw <= deposit);
        
        token.mint(address(this), deposit);
        token.approve(address(xToken), deposit);

        xToken.deposit(deposit, address(this));
        require(xToken.totalAssets() == deposit);

        xToken.withdraw(withdraw, address(this), address(this));
        require(xToken.totalAssets() == deposit - withdraw);
    }

    function testSyncRewardsFailsDuringCycle(uint128 seed, uint128 reward, uint256 warp) public {
        uint256 combined = uint256(seed) + uint256(reward);

        unchecked {
            hevm.assume(seed != 0 && reward !=0 && combined < type(uint128).max);
        }

        token.mint(address(this), seed);
        token.approve(address(xToken), seed);

        xToken.deposit(seed, address(this));
        token.mint(address(xToken), reward);
        xToken.syncRewards();
        warp = bound(warp, 0, 999);
        hevm.warp(warp);

        hevm.expectRevert(abi.encodeWithSignature("SyncError()"));
        xToken.syncRewards();
    }

    function testSyncRewardsAfterEmptyCycle(uint128 seed, uint128 reward) public {
        uint256 combined = uint256(seed) + uint256(reward);

        unchecked {
            hevm.assume(seed != 0 && reward !=0 && combined < type(uint128).max);
        }

        token.mint(address(this), seed);
        token.approve(address(xToken), seed);

        xToken.deposit(seed, address(this));
        require(xToken.totalAssets() == seed, "seed");
        hevm.warp(100);

        // sync with no new rewards
        xToken.syncRewards();
        require(xToken.lastRewardAmount() == 0);  
        require(xToken.lastSync() == 100);  
        require(xToken.rewardsCycleEnd() == 1000);  
        require(xToken.totalAssets() == seed);
        require(xToken.convertToShares(seed) == seed);

        // fast forward to next cycle and add rewards
        hevm.warp(1000);
        token.mint(address(xToken), reward); // seed new rewards

        xToken.syncRewards();
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == seed);
        require(xToken.convertToShares(seed) == seed);

        hevm.warp(2000);

        require(xToken.lastRewardAmount() == reward);  
        require(xToken.totalAssets() == combined);
        require(xToken.convertToAssets(seed) == combined);
        assertEq(xToken.convertToShares(combined), seed);
    }

    function testSyncRewardsAfterFullCycle(uint128 seed, uint128 reward, uint128 reward2) public {
        uint256 combined1 = uint256(seed) + uint256(reward);
        uint256 combined2 = uint256(seed) + uint256(reward) + reward2;

        unchecked {
            hevm.assume(seed != 0 && reward !=0 && reward2 != 0 && combined2 < type(uint128).max);
        }

        token.mint(address(this), seed);
        token.approve(address(xToken), seed);

        xToken.deposit(seed, address(this));
        require(xToken.totalAssets() == seed, "seed");
        hevm.warp(100);

        token.mint(address(xToken), reward); // seed new rewards
        // sync with new rewards
        xToken.syncRewards();
        require(xToken.lastRewardAmount() == reward);  
        require(xToken.lastSync() == 100);  
        require(xToken.rewardsCycleEnd() == 1000);  
        require(xToken.totalAssets() == seed);
        require(xToken.convertToShares(seed) == seed); // 1:1 still

        // // fast forward to next cycle and add rewards
        hevm.warp(1000);
        token.mint(address(xToken), reward2); // seed new rewards

        xToken.syncRewards();
        require(xToken.lastRewardAmount() == reward2);  
        require(xToken.totalAssets() == combined1);
        require(xToken.convertToAssets(seed) == combined1);

        hevm.warp(2000);

        require(xToken.lastRewardAmount() == reward2);  
        require(xToken.totalAssets() == combined2);
        require(xToken.convertToAssets(seed) == combined2);
    }
}