// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {IERC4626, IERC4626Router, ERC20} from "./interfaces/IERC4626Router.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {SelfPermit} from "./external/SelfPermit.sol";
import {Multicall} from "./external/Multicall.sol";

import {ENSReverseRecord} from "./ens/ENSReverseRecord.sol";

/// @title ERC4626Router contract
/// @author joeysantoro
contract ERC4626Router is IERC4626Router, SelfPermit, Multicall, ENSReverseRecord {
    using SafeTransferLib for ERC20;

    constructor(string memory name) ENSReverseRecord(name) {}

    /// @inheritdoc IERC4626Router
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        ERC20 underlying = vault.asset();

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        underlying.safeApprove(address(vault), amount);
        if ((sharesOut = vault.deposit(amount, to)) < minSharesOut) {
            revert MinAmountError();
        }
    }

    /// @inheritdoc IERC4626Router
    function withdrawFromVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        if ((sharesOut = vault.withdraw(amount, to, msg.sender)) < minSharesOut) {
            revert MinAmountError();
        }
    }

    /// @inheritdoc IERC4626Router
    function withdrawToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        fromVault.withdraw(amount, address(this), msg.sender);

        toVault.asset().safeApprove(address(toVault), amount);
        if ((sharesOut = toVault.deposit(amount, to)) < minSharesOut) {
            revert MinAmountError();
        }
    }

    /// @inheritdoc IERC4626Router
    function redeemFromVault(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        if ((amountOut = vault.redeem(shares, to, msg.sender)) < minAmountOut) {
            revert MinAmountError();
        }
    }

    /// @inheritdoc IERC4626Router
    function redeemToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        uint256 amount = fromVault.redeem(shares, address(this), msg.sender);

        toVault.asset().safeApprove(address(toVault), amount);
        if ((sharesOut = toVault.deposit(amount, to)) < minSharesOut) {
            revert MinAmountError();
        }
    }
}
