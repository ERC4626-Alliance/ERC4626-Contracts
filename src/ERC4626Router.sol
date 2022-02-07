// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./ERC4626RouterBase.sol";

import {ENSReverseRecord} from "./ens/ENSReverseRecord.sol";

/// @title ERC4626Router contract
/// @author joeysantoro
contract ERC4626Router is ERC4626RouterBase, ENSReverseRecord {
    using SafeTransferLib for ERC20;

    constructor(string memory name, IWETH9 weth) ENSReverseRecord(name) PeripheryPayments(weth) {}

    // For the below, no approval needed, assumes vault is already max approved

    /// @inheritdoc IERC4626Router
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        pullToken(vault.asset(), amount, address(this));
        return deposit(vault, to, amount, minSharesOut);
    }

    /// @inheritdoc IERC4626Router
    function withdrawToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        withdraw(fromVault, address(this), amount, 0);
        return deposit(toVault, to, amount, minSharesOut);
    }

    /// @inheritdoc IERC4626Router
    function redeemToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        uint256 amount = redeem(fromVault, address(this), shares, 0);
        return deposit(toVault, to, amount, minSharesOut);
    }

    function depositMax(
        IERC4626 vault, 
        address to,
        uint256 minSharesOut
    ) public returns (uint256 sharesOut) {
        ERC20 asset = vault.asset();
        uint256 assetBalance = asset.balanceOf(msg.sender);
        uint256 maxDeposit = vault.maxDeposit(to);
        uint256 amount = maxDeposit < assetBalance ? maxDeposit : assetBalance;
        pullToken(asset, amount, address(this));
        return deposit(vault, to, amount, minSharesOut);
    }

    function redeemMax(
        IERC4626 vault, 
        address to,
        uint256 minAmountOut
    ) public returns (uint256 amountOut) {
        uint256 shareBalance = vault.balanceOf(msg.sender);
        uint256 maxRedeem = vault.maxRedeem(msg.sender);
        uint256 amountShares = maxRedeem < shareBalance ? maxRedeem : shareBalance;
        return redeem(vault, to, amountShares, minAmountOut);
    }
}
