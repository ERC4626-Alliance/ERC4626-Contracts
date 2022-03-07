// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {IERC4626, IERC4626RouterBase, ERC20} from "./interfaces/IERC4626RouterBase.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {SelfPermit} from "./external/SelfPermit.sol";
import {Multicall} from "./external/Multicall.sol";
import {PeripheryPayments, IWETH9} from "./external/PeripheryPayments.sol";

/// @title ERC4626 Router Base Contract
/// @author joeysantoro
abstract contract ERC4626RouterBase is IERC4626RouterBase, SelfPermit, Multicall, PeripheryPayments {
    using SafeTransferLib for ERC20;

    /// @inheritdoc IERC4626RouterBase
    function mint(
        IERC4626 vault, 
        address to,
        uint256 shares,
        uint256 maxAmountIn
    ) public payable virtual override returns (uint256 amountIn) {
        if ((amountIn = vault.mint(shares, to)) > maxAmountIn) {
            revert MaxAmountError();
        }
    }

    /// @inheritdoc IERC4626RouterBase
    function deposit(
        IERC4626 vault, 
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        if ((sharesOut = vault.deposit(amount, to)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    /// @inheritdoc IERC4626RouterBase
    function withdraw(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 maxSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        if ((sharesOut = vault.withdraw(amount, to, msg.sender)) > maxSharesOut) {
            revert MaxSharesError();
        }
    }

    /// @inheritdoc IERC4626RouterBase
    function redeem(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) public payable virtual override returns (uint256 amountOut) {
        if ((amountOut = vault.redeem(shares, to, msg.sender)) < minAmountOut) {
            revert MinAmountError();
        }
    }
}
