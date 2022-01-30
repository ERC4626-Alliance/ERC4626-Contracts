// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate-next/tokens/ERC20.sol";
import "../AuthERC4626.sol";

import {LibFuse} from "libcompound/LibFuse.sol";
import {CERC20} from "libcompound/interfaces/CERC20.sol";

contract CompoundERC4626 is AuthERC4626 {
    using LibFuse for CERC20;
    using SafeTransferLib for ERC20;

    CERC20 public immutable cToken;

    constructor(
        CERC20 _cToken,
        string memory _name,
        string memory _symbol,
        address _owner,
        Authority _authority

    )
        AuthERC4626(
            ERC20(address(_cToken.underlying())),
            _name,
            _symbol,
            _owner,
            _authority
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

    /// @notice allow an authenticated address to recover a specific token
    function recoverERC20(ERC20 token, address to) external requiresAuth {
        _transferAll(token, to);
    }

    function _transferAll(ERC20 token, address to) internal returns (uint256 amount) {
        token.safeTransfer(to, amount = token.balanceOf(address(this)));
    }
}