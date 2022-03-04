// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20, ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {LibFuse} from "libcompound/LibFuse.sol";
import {CERC20} from "libcompound/interfaces/CERC20.sol";

contract FuseERC4626 is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
    using LibFuse for CERC20;

    /// @notice CERC20 token reference
    CERC20 public immutable cToken;

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    ERC20 public immutable cTokenUnderlying;

    /// @notice CompoundERC4626 constructor
    /// @param _cToken Compound cToken to wrap
    /// @param name ERC20 name of the vault shares token
    /// @param symbol ERC20 symbol of the vault shares token
    constructor(
        address _cToken,
        string memory name,
        string memory symbol
    ) ERC4626(ERC20(CERC20(_cToken).underlying()), name, symbol) {
        cToken = CERC20(_cToken);
        cTokenUnderlying = ERC20(CERC20(cToken).underlying());
    }

    function beforeWithdraw(uint256 underlyingAmount, uint256) internal override {
        // Withdraw the underlying tokens from the cToken.
        require(cToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");
    }

    function afterDeposit(uint256 underlyingAmount, uint256) internal override {
        // Approve the underlying tokens to the cToken
        asset.safeApprove(address(cToken), underlyingAmount);

        // mint tokens
        require(cToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() public view override returns(uint256) {
        // Use libfuse to determine an accurate view exchange rate.
        // this use Fuse cToken functions that do not exist in Compound implementations:
        // - cToken.totalAdminFees()
        // - cToken.totalFuseFees()
        // - cToken.adminFeeMantissa()
        return cToken.viewUnderlyingBalanceOf(address(this));
    }
}
