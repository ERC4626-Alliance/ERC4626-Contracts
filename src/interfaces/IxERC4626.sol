// SPDX-License-Identifier: MIT
// Rewards logic inspired by xERC20 (https://github.com/ZeframLou/playpen/blob/main/src/xERC20.sol)

pragma solidity ^0.8.0;

import "solmate/mixins/ERC4626.sol";
import "solmate/utils/SafeCastLib.sol";

/** 
 @title  An xERC4626 Single Staking Contract Interface
 @notice This contract allows users to autocompound rewards denominated in an underlying reward token. 
         It is fully compatible with [ERC4626](https://eips.ethereum.org/EIPS/eip-4626) allowing for DeFi composability.
         It maintains balances using internal accounting to prevent instantaneous changes in the exchange rate.
         NOTE: an exception is at contract creation, when a reward cycle begins before the first deposit. After the first deposit, exchange rate updates smoothly.

         Operates on "cycles" which distribute the rewards surplus over the internal balance to users linearly over the remainder of the cycle window.
*/
interface IxERC4626 {
    /*////////////////////////////////////////////////////////
                        Custom Errors
    ////////////////////////////////////////////////////////*/

    /// @dev thrown when syncing before cycle ends.
    error SyncError();

    /*////////////////////////////////////////////////////////
                            Events
    ////////////////////////////////////////////////////////*/

    /// @dev emit every time a new rewards cycle starts
    event NewRewardsCycle(uint32 indexed cycleEnd, uint256 rewardAmount);

    /*////////////////////////////////////////////////////////
                        View Methods
    ////////////////////////////////////////////////////////*/

    /// @notice the maximum length of a rewards cycle
    function rewardsCycleLength() external view returns (uint32);

    /// @notice the effective start of the current cycle
    /// NOTE: This will likely be after `rewardsCycleEnd - rewardsCycleLength` as this is set as block.timestamp of the last `syncRewards` call.
    function lastSync() external view returns (uint32);

    /// @notice the end of the current cycle. Will always be evenly divisible by `rewardsCycleLength`.
    function rewardsCycleEnd() external view returns (uint32);

    /// @notice the amount of rewards distributed in a the most recent cycle
    function lastRewardAmount() external view returns (uint192);

    /*////////////////////////////////////////////////////////
                    State Changing Methods
    ////////////////////////////////////////////////////////*/

    /// @notice Distributes rewards to xERC4626 holders.
    /// All surplus `asset` balance of the contract over the internal balance becomes queued for the next cycle.
    function syncRewards() external;
}
