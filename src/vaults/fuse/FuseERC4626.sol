// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20, ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {LibFuse} from "libcompound/LibFuse.sol";
import {CToken} from "../../external/fuse/CToken.sol";
import {Unitroller} from "../../external/fuse/Unitroller.sol";

contract FuseERC4626 is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
    using LibFuse for CToken;

    /// @notice CToken token reference
    CToken public immutable cToken;

    /// @notice reference to the Unitroller of the CToken token
    Unitroller public immutable unitroller;

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
    ) ERC4626(ERC20(CToken(_cToken).underlying()), name, symbol) {
        cToken = CToken(_cToken);
        unitroller = Unitroller(cToken.comptroller());
        cTokenUnderlying = ERC20(CToken(cToken).underlying());
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

    /// @notice maximum amount of assets that can be deposited.
    /// This is capped by the amount of assets the cToken can be
    /// supplied with.
    /// This is 0 if minting is paused on the cToken.
    function maxDeposit(address) public view override returns (uint256) {
        address cTokenAddress = address(cToken);

        if (unitroller.mintGuardianPaused(cTokenAddress)) return 0;

        uint256 supplyCap = unitroller.supplyCaps(cTokenAddress);
        if (supplyCap == 0) return type(uint256).max;

        uint256 assetsDeposited = cToken.totalSupply().mulWadDown(cToken.viewExchangeRate());
        return supplyCap - assetsDeposited;
    }

    /// @notice maximum amount of shares that can be minted.
    /// This is capped by the amount of assets the cToken can be
    /// supplied with.
    /// This is 0 if minting is paused on the cToken.
    function maxMint(address) public view override returns (uint256) {
        address cTokenAddress = address(cToken);

        if (unitroller.mintGuardianPaused(cTokenAddress)) return 0;

        uint256 supplyCap = unitroller.supplyCaps(cTokenAddress);
        if (supplyCap == 0) return type(uint256).max;

        uint256 assetsDeposited = cToken.totalSupply().mulWadDown(cToken.viewExchangeRate());
        return convertToShares(supplyCap - assetsDeposited);
    }

    /// @notice Maximum amount of assets that can be withdrawn.
    /// This is capped by the amount of cash available on the cToken,
    /// if all assets are borrowed, a user can't withdraw from the vault.
    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = cToken.getCash();
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    /// @notice Maximum amount of shares that can be redeemed.
    /// This is capped by the amount of cash available on the cToken,
    /// if all assets are borrowed, a user can't redeem from the vault.
    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 cash = cToken.getCash();
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }
}
