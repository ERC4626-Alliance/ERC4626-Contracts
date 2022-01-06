// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./interfaces/IERC4626.sol";
import "./interfaces/IERC4626Router.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title ERC4626Router contract
/// @author joeysantoro 
contract ERC4626Router is IERC4626Router {
    using SafeTransferLib for ERC20;

    /************************** Deposit **************************/

    /// @inheritdoc IERC4626Router
    function depositToApproveVault(
        IERC4626 vault, 
        address to, 
        uint256 amountIn,
        uint256 minSharesOut
    ) external returns(uint256 sharesOut) {
        ERC20 underlying = vault.underlying();

        underlying.safeTransferFrom(msg.sender, address(this), amountIn);
        underlying.safeApprove(address(vault), amountIn);
        if (vault.deposit(to, amountIn) < minSharesOut) {
            revert(MinAmountError());
        }
    }

    /// @inheritdoc IERC4626Router
    function depositToOptimisticVault(
        IERC4626 vault, 
        address to, 
        uint256 amountIn,
        uint256 minSharesOut
    ) external returns(uint256 sharesOut) {        
        ERC20 underlying = vault.underlying();

        underlying.safeTransferFrom(msg.sender, address(vault), amountIn);
        if (vault.deposit(to, amountIn) < minSharesOut) {
            revert(MinAmountError());
        }
    }

    /************************** Withdraw **************************/

    /// @inheritdoc IERC4626Router
    function withdrawToApproveVault(
        IERC4626 fromVault, 
        IERC4626 toVault,
        address to, 
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns(uint256 sharesOut) {
        ERC20 underlying = fromVault.underlying();
        if (underlying != toVault.underlying()) {
            revert(UnderlyingMismatchError());
        }

        fromVault.withdrawFrom(msg.sender, address(this), amountUnderlying);

        underlying.safeApprove(address(toVault), amountUnderlying);
        if (toVault.deposit(to, amountUnderlying) < minSharesOut) {
            revert(MinAmountError());
        }
    }

    /// @inheritdoc IERC4626Router
    function withdrawToOptimisticVault(
        IERC4626 fromVault, 
        IERC4626 toVault,
        address to, 
        uint256 amountUnderying,
        uint256 minSharesOut
    ) external returns(uint256 sharesOut) {
        ERC20 underlying = fromVault.underlying();
        if (underlying != toVault.underlying()) {
            revert(UnderlyingMismatchError());
        }

        fromVault.withdrawFrom(msg.sender, address(toVault), amountUnderying);

        if (toVault.deposit(to, amountUnderying) < minSharesOut) {
            revert(MinAmountError());
        }
    }


    /************************** Redeem **************************/

    /// @inheritdoc IERC4626Router
    function redeemToApproveVault(
        IERC4626 fromVault, 
        IERC4626 toVault,
        address to, 
        uint256 amountShares,
        uint256 minSharesOut
    ) external returns(uint256 sharesOut) {
        ERC20 underlying = fromVault.underlying();
        if (underlying != toVault.underlying()) {
            revert(UnderlyingMismatchError());
        }

        uint256 amountUnderlying = fromVault.redeemFrom(msg.sender, address(this), amountShares);

        underlying.safeApprove(address(toVault), amountUnderlying);
        if (toVault.deposit(to, amountUnderlying) < minAmountOut) {
            revert(MinAmountError());
        }
    }

    /// @inheritdoc IERC4626Router
    function redeemToOptimisticVault(
        IERC4626 fromVault, 
        IERC4626 toVault,
        address to, 
        uint256 amountShares,
        uint256 minSharesOut
    ) external returns(uint256 sharesOut) {
        ERC20 underlying = fromVault.underlying();
        if (underlying != toVault.underlying()) {
            revert(UnderlyingMismatchError());
        }

        uint256 amountUnderlying = fromVault.redeemFrom(msg.sender, address(toVault), amountShares);

        if (toVault.deposit(to, amountUnderlying) < minSharesOut) {
            revert(MinAmountError());
        }
    }
}