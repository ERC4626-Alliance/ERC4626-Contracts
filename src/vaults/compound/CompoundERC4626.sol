// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20, ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {LibFuse} from "libcompound/LibFuse.sol";
import {CERC20} from "libcompound/interfaces/CERC20.sol";

contract CompoundERC4626 is ERC4626 {
    using LibFuse for CERC20;
    using SafeTransferLib for ERC20;

    CERC20 public immutable cToken;

    constructor(
        CERC20 _cToken
    )
        ERC4626(
            ERC20(address(_cToken.underlying())),
            string(abi.encodePacked(_cToken.underlying().name(), " ERC-4626 Vault")),
            string(abi.encodePacked("w", _cToken.underlying().symbol()))
        )
    {
        cToken = _cToken;
    }

    function beforeWithdraw(uint256 underlyingAmount) internal override {
        // Withdraw the underlying tokens from the cToken.
        require(cToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");
    }

    function afterDeposit(uint256 underlyingAmount) internal override {
        // Approve the underlying tokens to the cToken
        underlying.safeApprove(address(cToken), underlyingAmount);

        // mint tokens
        require(cToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    function totalUnderlying() public view override returns (uint256) {
        return cToken.viewUnderlyingBalanceOf(address(this));
    }
}