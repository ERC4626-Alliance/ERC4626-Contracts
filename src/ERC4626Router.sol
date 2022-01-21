// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./interfaces/IERC4626.sol";
import "./interfaces/IERC4626Router.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title ERC4626Router contract
/// @author joeysantoro
contract ERC4626Router is IERC4626Router {
    using SafeTransferLib for ERC20;

    /// @inheritdoc IERC4626Router
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        ERC20 underlying = vault.underlying();

        underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
        underlying.safeApprove(address(vault), amountUnderlying);
        if (sharesOut = vault.deposit(to, amountUnderlying) < minSharesOut) {
            revert MinAmountError();
        }
    }

    /// @inheritdoc IERC4626Router
    function withdrawToVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        fromVault.withdrawFrom(msg.sender, address(this), amountUnderlying);

        toVault.underlying().safeApprove(address(toVault), amountUnderlying);
        if (sharesOut = toVault.deposit(to, amountUnderlying) < minSharesOut) {
            revert MinAmountError();
        }
    }

    /// @inheritdoc IERC4626Router
    function redeemToVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountShares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        uint256 amountUnderlying = fromVault.redeemFrom(msg.sender, address(this), amountShares);

        toVault.underlying().safeApprove(address(toVault), amountUnderlying);
        if (sharesOut = toVault.deposit(to, amountUnderlying) < minSharesOut) {
            revert MinAmountError();
        }
    }
}
