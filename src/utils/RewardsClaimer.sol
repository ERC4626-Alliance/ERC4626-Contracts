// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

/// @title Rewards Claiming Contract
/// @author joeysantoro
contract RewardsClaimer {
    using SafeTransferLib for ERC20;

    event RewardDestinationUpdate(address indexed newDestination);

    event ClaimRewards(address indexed rewardToken, uint256 amount);

    /// @notice the address to send rewards
    address public rewardDestination;

    /// @notice the array of reward tokens to send to
    ERC20[] public rewardTokens;

    constructor(
        address _rewardDestination, 
        ERC20[] memory _rewardTokens
    ) {
        rewardDestination = _rewardDestination;
        rewardTokens = _rewardTokens;
    }

    /// @notice claim all token rewards
    function claimRewards() public {
        beforeClaim(); // hook to accrue/pull in rewards, if needed

        // send all tokens to destination
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            ERC20 token = rewardTokens[i];
            emit ClaimRewards(address(token), _transferAll(token, rewardDestination));
        }
    }

    /// @notice set the address of the new reward destination
    /// @param newDestination the new reward destination
    function setRewardDestination(address newDestination) external {
        require(msg.sender == rewardDestination, "UNAUTHORIZED");
        rewardDestination = newDestination;
        emit RewardDestinationUpdate(newDestination);
    }

    /// @notice hook to accrue/pull in rewards, if needed
    function beforeClaim() internal virtual {}

    function _transferAll(ERC20 token, address to) internal returns (uint256 amount) {
        token.safeTransfer(to, amount = token.balanceOf(address(this)));
    }
}