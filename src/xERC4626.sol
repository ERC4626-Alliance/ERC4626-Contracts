// SPDX-License-Identifier: MIT
// Rewards logic inspired by xERC20 (https://github.com/ZeframLou/playpen/blob/main/src/xERC20.sol)

pragma solidity ^0.8.0;

import "solmate/mixins/ERC4626.sol";
import "solmate/utils/SafeCastLib.sol";

/** 
 @title  An xERC4626 Single Staking Contract
 @notice This contract allows users to autocompound rewards denominated in an underlying reward token. 
         It is fully compatible with ERC4626 allowing for DeFi composability.
         It maintains balances using internal accounting to prevent instantaneous changes in the exchange rate.
         NOTE: an exception is at contract creation, when a reward cycle begins before the first deposit. After the first deposit, exchange rate updates smoothly.
*/
abstract contract xERC4626 is ERC4626 {
    using SafeCastLib for *;

    /// @dev thrown when syncing before cycle ends.
    error SyncError();

    /// @dev emit every time a new rewards cycle starts
    event NewRewardsCycle(uint32 indexed cycleEnd, uint256 rewardAmount);

    /// @notice the length of a rewards cycle
    uint32 public immutable rewardsCycleLength;

    /// @notice the delayed start of the current cycle
    uint32 public lastSync;

    /// @notice the end of the current cycle
    uint32 public rewardsCycleEnd;

    /// @notice the amount of rewards distributed in a given cycle
    uint192 public lastRewardAmount;

    uint256 internal storedTotalAssets;

    constructor(uint32 _rewardsCycleLength) {
        rewardsCycleLength = _rewardsCycleLength;
        // seed initial rewardsCycleEnd
        rewardsCycleEnd = block.timestamp.safeCastTo32() / rewardsCycleLength * rewardsCycleLength;
    }

    /// @notice Compute the amount of tokens available to share holders.
    ///         Increases linearly during a reward distribution period from the sync call, not the cycle start.
    function totalAssets() public view override returns (uint256) {
        // cache global vars
        uint256 storedTotalAssets_ = storedTotalAssets;
        uint192 lastRewardAmount_ = lastRewardAmount;
        uint32 rewardsCycleEnd_ = rewardsCycleEnd;
        uint32 lastSync_ = lastSync;
        
        if (block.timestamp >= rewardsCycleEnd_) {
            // no rewards or rewards fully unlocked
            // entire reward amount is available
            return storedTotalAssets_ + lastRewardAmount_;
        } 


        // rewards not fully unlocked
        // add unlocked rewards to stored total
        uint256 unlockedRewards = lastRewardAmount_ * (block.timestamp - lastSync_) / (rewardsCycleEnd_ - lastSync_);
        return storedTotalAssets_ + unlockedRewards;
    }

    // Update storedTotalAssets on withdraw/redeem
    function beforeWithdraw(uint256 amount, uint256 shares) internal virtual override {
        super.beforeWithdraw(amount, shares);
        storedTotalAssets -= amount;
    }

    // Update storedTotalAssets on deposit/mint
    function afterDeposit(uint256 amount, uint256 shares) internal virtual override {
        storedTotalAssets += amount;
        super.afterDeposit(amount, shares);
    }

    /// @notice Distributes rewards to xERC4626 holders
    /// All surplus `asset` balance of the contract becomes queued for the next cycle
    function syncRewards() external virtual {
        uint192 lastRewardAmount_ = lastRewardAmount;
        uint32 timestamp = block.timestamp.safeCastTo32();

        if (timestamp < rewardsCycleEnd) revert SyncError();

        uint256 storedTotalAssets_ = storedTotalAssets;
        uint256 nextRewards = asset.balanceOf(address(this)) - storedTotalAssets_ - lastRewardAmount_;

        storedTotalAssets = storedTotalAssets_ + lastRewardAmount_; // SSTORE

        uint32 end = (timestamp + rewardsCycleLength) / rewardsCycleLength * rewardsCycleLength;
        
        // Combined single SSTORE
        lastRewardAmount = nextRewards.safeCastTo192();
        lastSync = timestamp;
        rewardsCycleEnd = end;

        emit NewRewardsCycle(end, nextRewards);
    }
}