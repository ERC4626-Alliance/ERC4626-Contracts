// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20, ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {RewardsClaimer} from "../../utils/RewardsClaimer.sol";

// Docs: https://docs.convexfinance.com/convexfinanceintegration/booster

// main Convex contract(booster.sol) basic interface
interface IConvexBooster {
    // deposit into convex, receive a tokenized deposit. parameter to stake immediately
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
}

interface IConvexBaseRewardPool {
    function pid() external view returns (uint256);
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function extraRewards(uint256 index) external view returns(IRewards);
    function extraRewardsLength() external view returns(uint);
    function rewardToken() external view returns(ERC20);
}

interface IRewards {
    function rewardToken() external view returns(ERC20);
}

/// @title Convex Finance Yield Bearing Vault
/// @author joeysantoro
contract ConvexERC4626 is ERC4626, RewardsClaimer {
    using SafeTransferLib for ERC20;

    /// @notice The Convex Booster contract (for deposit/withdraw)
    IConvexBooster public immutable convexBooster;
    
    /// @notice The Convex Rewards contract (for claiming rewards)
    IConvexBaseRewardPool public immutable convexRewards;

    /**
     @notice Creates a new Vault that accepts a specific underlying token.
     @param _asset The ERC20 compliant token the Vault should accept.
     @param _name The name for the vault token.
     @param _symbol The symbol for the vault token.
     @param _convexBooster The Convex Booster contract (for deposit/withdraw).
     @param _convexRewards The Convex Rewards contract (for claiming rewards).
     @param _rewardsDestination the address to send CRV and CVX.
     @param _rewardTokens the rewards tokens to send out.
    */
    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        IConvexBooster _convexBooster,
        IConvexBaseRewardPool _convexRewards,
        address _rewardsDestination,
        ERC20[] memory _rewardTokens
    )
        ERC4626(_asset, _name, _symbol)
        RewardsClaimer(_rewardsDestination, _rewardTokens)
    {
        convexBooster = _convexBooster;
        convexRewards = _convexRewards;
    }

    function updateRewardTokens() public {
        uint256 len = convexRewards.extraRewardsLength();
        require(len < 5, "exceed max rewards");
        delete rewardTokens;

        for (uint256 i = 0; i < len; i++) {
            rewardTokens.push(convexRewards.extraRewards(i).rewardToken());
        }
        rewardTokens.push(convexRewards.rewardToken());
    }

    function afterDeposit(uint256 amount, uint256) internal override {
        uint256 poolId = convexRewards.pid();
        asset.safeApprove(address(convexBooster), amount);
        convexBooster.deposit(poolId, amount, true);
    }

    function beforeWithdraw(uint256 amount, uint256) internal override {
        convexRewards.withdrawAndUnwrap(amount, false);
    }

    function beforeClaim() internal override {
        convexRewards.getReward(address(this), true);
    }

    /// @notice Calculates the total amount of underlying tokens the Vault holds.
    /// @return The total amount of underlying tokens the Vault holds.
    function totalAssets() public view override returns (uint256) {
        return convexRewards.balanceOf(address(this));
    }
}
