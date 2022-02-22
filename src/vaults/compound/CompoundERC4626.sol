// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./CErc20.sol";
import "../../interfaces/IERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title ERC4626 wrapper around a Cerc20
/// @author Fei Protocol
contract CompoundERC4626 is IERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
    using SafeTransferLib for CErc20;

    /// @notice CErc20 token reference
    CErc20 public immutable cToken;

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    ERC20 public immutable cTokenUnderlying;

    /*///////////////////////////////////////////////////////////////
                Constructor
    //////////////////////////////////////////////////////////////*/
    /// @notice CompoundERC4626 constructor
    /// @param _cToken Compound cToken to wrap
    /// @param name ERC20 name of the vault shares token
    /// @param symbol ERC20 symbol of the vault shares token
    constructor(
        address _cToken,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol, 18) {
        require(CErc20(_cToken).isCToken(), "CompoundERC4626: not a cToken");
        require(!CErc20(_cToken).isCEther(), "CompoundERC4626: cEther not supported");
        cToken = CErc20(_cToken);
        cTokenUnderlying = ERC20(CErc20(cToken).underlying());
    }

    /*///////////////////////////////////////////////////////////////
                ERC4626 Vault properties
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view override returns(address) {
        return address(cTokenUnderlying);
    }

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    /// @dev note that the amount might not be 100% exact,
    /// as totalBorrows() does not account for the accumulated
    /// interest since last cToken interaction (it uses exchangeRateStored).
    function totalAssets() external view override returns(uint256) {
        // totalBorrows is slightly off because 
        return cToken.getCash() + cToken.totalBorrows();
    }

    /*///////////////////////////////////////////////////////////////
                ERC4626 Deposit/Withdrawal logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints `shares` Vault shares to `receiver` by
    /// depositing exactly `amount` of underlying tokens.
    function deposit(uint256 assets, address receiver) external override returns(uint256 shares) {
        // enter vault (mint shares, deposit underlying in cToken)
        return shares = _enterVault(assets, receiver);
    }

    /// @notice Mints exactly `shares` Vault shares to `receiver`
    /// by depositing `amount` of underlying tokens.
    /// @dev the exchangeRateCurrent() is used, so the cToken will
    /// accumulate interest. Amount of assets is rounded up, and
    /// amount of shares minted is rounded down, so the desired and
    /// actual amount of shares minted should match.
    function mint(uint256 shares, address receiver) external override returns(uint256 assets) {
        // compute exact amount of assets to send
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        assets = shares.mulWadUp(exchangeRate);

        // enter vault (mint shares, deposit underlying in cToken)
        uint256 actualShares = _enterVault(assets, receiver);

        // double check no rounding errors
        assert(shares == actualShares);

        return assets;
    }

    /// @notice Enter the vault with `assets` assets, and mints `shares`
    /// shares to the user `receiver`.
    function _enterVault(uint256 assets, address receiver) internal returns(uint256 shares) {
        // transfer user tokens to self
        cTokenUnderlying.safeTransferFrom(msg.sender, address(this), assets);

        // mint cTokens
        cTokenUnderlying.approve(address(cToken), assets);
        uint256 balanceBefore = totalSupply; // identical to cToken.balanceOf(address(this))
        require(cToken.mint(assets) == 0, "CompoundERC4626: error on cToken.mint");
        shares = cToken.balanceOf(address(this)) - balanceBefore;

        // mint shares to receiver
        _mint(receiver, shares);

        // emit event
        emit Deposit(msg.sender, receiver, assets, shares);

        // return the amount of shares minted
        return shares;
    }

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function withdraw(uint256 assets, address receiver, address owner) external override returns(uint256 shares) {
        // redeem cTokens and get the actual number of shares burnt
        // This is done before allowance check, because we don't know
        // the actual number of shares burnt until we redeem.
        uint256 balanceBefore = totalSupply; // identical to cToken.balanceOf(address(this))
        require(cToken.redeemUnderlying(assets) == 0, "CompoundERC4626: error on cToken.redeemUnderlying");
        shares = balanceBefore - cToken.balanceOf(address(this));

        // Check that owner approved spending on behalf of the caller
        // Then, Burn the owner's shares.
        // This checks that the owner has enough shares.
        _updateAllowanceAndBurnShares(owner, shares);

        // transfer underlying to receiver
        cTokenUnderlying.transfer(receiver, assets);

        // emit event
        emit Withdraw(msg.sender, receiver, assets, shares);

        return shares;
    }

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(uint256 shares, address receiver, address owner) external override returns(uint256 assets) {
        // Check that owner approved spending on behalf of the caller
        // Then, Burn the owner's shares.
        // This checks that the owner has enough shares.
        _updateAllowanceAndBurnShares(owner, shares);

        // redeem cTokens
        require(cToken.redeem(shares) == 0, "CompoundERC4626: error on cToken.redeemUnderlying");
        assets = cTokenUnderlying.balanceOf(address(this)); // 0 balance before

        // transfer underlying to receiver
        cTokenUnderlying.transfer(receiver, assets);

        // emit event
        emit Withdraw(msg.sender, receiver, assets, shares);

        return assets;
    }

    /// @notice Check that owner approved spending on behalf of the caller.
    /// Then, Burn the owner's shares. This checks that the owner has enough shares.
    function _updateAllowanceAndBurnShares(address owner, uint256 shares) internal {
        // Check that owner approved spending on behalf of the caller
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            require(allowed >= shares, "CompoundERC4626: spender not authorized");
            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        // Burn the owner's shares
        // This checks that the owner has enough shares,
        // because the owner balance underflows otherwise.
        _burn(owner, shares);
    }

    /*///////////////////////////////////////////////////////////////
                ERC4626 Vault Accounting Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) public view override returns(uint256 shares) {
        return assets * 1e18 / cToken.exchangeRateStored();
    }

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) public view override returns(uint256 assets) {
        return shares * cToken.exchangeRateStored() / 1e18;
    }

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address/* owner*/) external pure override returns(uint256 maxAssets) {
        return type(uint256).max;
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets) external view override returns(uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address/* owner*/) external pure override returns(uint256 maxShares) {
        return type(uint256).max;
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares) external view override returns(uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner) external view override returns(uint256 maxAssets) {
        uint256 sharesOwned = balanceOf[owner];
        return convertToAssets(sharesOwned);
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view override returns(uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner) external view override returns(uint256 maxShares) {
        return balanceOf[owner];
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares) external view override returns(uint256 assets) {
        return convertToAssets(shares);
    }
}
