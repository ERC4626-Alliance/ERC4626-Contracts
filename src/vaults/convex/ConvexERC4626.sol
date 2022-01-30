// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "../AuthERC4626.sol";

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
}

/// @title Convex Finance Yield Bearing Vault with a single owner
/// @author joeysantoro
contract ConvexAuthERC4626 is AuthERC4626 {
    using SafeTransferLib for ERC20;

    event RewardDestinationUpdate(address indexed newDestination);

    event ClaimRewards(uint256 cvxAmount, uint256 crvAmount);

    /// @notice The Convex Booster contract (for deposit/withdraw)
    IConvexBooster public immutable convexBooster;
    
    /// @notice The Convex Rewards contract (for claiming rewards)
    IConvexBaseRewardPool public immutable convexRewards;

    /// @notice the address to send CRV and CVX
    address public rewardDestination;

    ERC20 public constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    ERC20 public constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    /// @notice Creates a new Vault that accepts a specific underlying token.
    /// @param _underlying The ERC20 compliant token the Vault should accept.
    /// @param _name The name for the vault token.
    /// @param _symbol The symbol for the vault token.
    /// @param _owner the owner of the Vault, should be the fToken plugin delegator
    /// @param _authority the Vault Authority which manages function access control.
    /// @param _convexBooster The Convex Booster contract (for deposit/withdraw).
    /// @param _convexRewards The Convex Rewards contract (for claiming rewards).
    /// @param _rewardsDestination the address to send CRV and CVX.
    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol,
        address _owner,
        Authority _authority,
        IConvexBooster _convexBooster,
        IConvexBaseRewardPool _convexRewards,
        address _rewardsDestination
    )
        AuthERC4626(
            _underlying,
            _name,
            _symbol,
            _owner,
            _authority 
        )
    {
        convexBooster = _convexBooster;
        convexRewards = _convexRewards;
        rewardDestination = _rewardsDestination;
    }

    function afterDeposit(uint256 underlyingAmount) internal override {
        uint256 poolId = convexRewards.pid();
        underlying.approve(address(convexBooster), underlyingAmount);
        convexBooster.deposit(poolId, underlyingAmount, true);
    }

    function beforeWithdraw(uint256 underlyingAmount) internal override {
        convexRewards.withdrawAndUnwrap(underlyingAmount, false);
    }

    /// @notice claim CRV & CVX rewards earned by the LP tokens staked on this contract.
    function claimRewards() public {
        convexRewards.getReward(address(this), true);
        emit ClaimRewards(
            _transferAll(CVX, rewardDestination), 
            _transferAll(CRV, rewardDestination)
        );
    }

    /// @notice Calculates the total amount of underlying tokens the Vault holds.
    /// @return totalUnderlyingHeld The total amount of underlying tokens the Vault holds.
    function totalUnderlying() public view override returns (uint256) {
        return convexRewards.balanceOf(address(this));
    }

    /// @notice allow an authenticated address to recover a specific token
    function recoverERC20(ERC20 token, address to) external requiresAuth {
        _transferAll(token, to);
    }

    function setRewardDestination(address newDestination) external requiresAuth {
        rewardDestination = newDestination;
        emit RewardDestinationUpdate(newDestination);
    }

    function _transferAll(ERC20 token, address to) internal returns (uint256 amount) {
        token.safeTransfer(to, amount = token.balanceOf(address(this)));
    }
}
