// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

abstract contract IERC4626 is ERC20 {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed from, address indexed to, uint256 value);

    event Withdraw(address indexed from, address indexed to, uint256 value);

    /*///////////////////////////////////////////////////////////////
                            Mutable Functions
    //////////////////////////////////////////////////////////////*/

    /**
      @notice Deposit a specific amount of assets.
      @param amount The amount of the assets to deposit.
      @param to The address to receive shares corresponding to the deposit
      @return shares The shares in the vault credited to `to`
    */
    function deposit(uint256 amount, address to) public virtual returns (uint256 shares);

    /**
      @notice Mint an exact amount of shares for a variable amount of assets.
      @param shares The amount of vault shares to mint.
      @param to The address to receive shares corresponding to the mint.
      @return amount The amount of the assets deposited from the mint call.
    */
    function mint(uint256 shares, address to) public virtual returns (uint256 amount);

    /**
      @notice Withdraw a specific amount of assets.
      @param amount The amount of the assets to withdraw.
      @param to The address to receive assets corresponding to the withdrawal.
      @param from The address to burn shares from corresponding to the withdrawal.
      @return shares The shares in the vault burned from sender
    */
    function withdraw(uint256 amount, address to, address from) public virtual returns (uint256 shares);

    /**
      @notice Redeem a specific amount of shares for assets.
      @param from The address to burn shares from corresponding to the redemption.
      @param to The address to receive assets corresponding to the redemption.
      @param shares The amount of shares to redeem.
      @return amount The asset amount transferred to `to`.
    */
    function redeem(uint256 shares, address to, address from) public virtual returns (uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /** 
      @notice The underlying asset the Vault accepts.
      @return the ERC20 implementation address.
    */
    function asset() public view virtual returns (ERC20);

    /** 
      @notice Returns a user's Vault balance in assets.
      @param user The user to get the asset balance of.
      @return amount The user's Vault balance in assets.
    */
    function assetsOf(address user) public view virtual returns (uint256 amount);

    /** 
      @notice Calculates the total amount of assets the Vault manages.
      @return The total amount of assets the Vault manages.
    */
    function totalAssets() public view virtual returns (uint256);

    /** 
      @notice Returns the value in assets of one vault share. 
     */
    function exchangeRate() public view virtual returns (uint256);

    /**
      @notice Returns the amount of vault tokens that would be obtained if depositing a given amount of underlying tokens in a `deposit` call.
      @param amount the input amount of assets
      @return shares the corresponding amount of shares out from a deposit call with `amount` in
     */
    function previewDeposit(uint256 amount) public view virtual returns (uint256 shares);

    /**
      @notice Returns the amount of assets that would be deposited if minting a given amount of shares in a `mint` call.
      @param shares the amount of shares from a mint call.
      @return amount the amount of assets corresponding to the mint call
     */
    function previewMint(uint256 shares) public view virtual returns (uint256 amount);

    /**
      @notice Returns the amount of vault tokens that would be burned if withdrawing a given amount of underlying tokens in a `withdraw` call.
      @param amount the input amount of assets
      @return shares the corresponding amount of shares out from a withdraw call with `amount` in
     */
    function previewWithdraw(uint256 amount) public view virtual returns (uint256 shares);

    /**
      @notice Returns the amount of assets that would be obtained if redeeming a given amount of shares in a `redeem` call.
      @param shares the amount of shares from a redeem call.
      @return amount the amount of assets corresponding to the redeem call
     */
    function previewRedeem(uint256 shares) public view virtual returns (uint256 amount);

    /**
      @notice Returns the max deposit amount for a recipient
      @param to the deposit recipient
      @return amount the max input amount of assets for deposit for a user
    */
    function maxDeposit(address to) public view virtual returns (uint256 amount);

    /**
      @notice Returns the max mint shares for a recipient
      @param to the mint recipient
      @return shares the max shares for mint for a user
    */
    function maxMint(address to) public view virtual returns (uint256 shares);

    /**
      @notice Returns the max withdraw amount for a user
      @param from the withdraw source
      @return amount the max amount of assets out for withdraw for a user
    */
    function maxWithdraw(address from) public view virtual returns (uint256 amount);

    /**
      @notice Returns the max redeem shares for a user
      @param from the redeem source
      @return shares the max shares out for redeem for a user
    */
    function maxRedeem(address from) public view virtual returns (uint256 shares);
}
