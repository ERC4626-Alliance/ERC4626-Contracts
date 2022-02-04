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

    function redeemToDepositMax(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        redeemMax(fromVault, address(this), 0);
        return depositMax(toVault, to, minSharesOut);
    }
}
