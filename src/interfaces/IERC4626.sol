// SPDX-License-Identifier: AGPL-3.0-only
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
      @notice Deposit a specific amount of underlying tokens.
      @param to The address to receive shares corresponding to the deposit
      @param underlyingAmount The amount of the underlying token to deposit.
      @return shares The shares in the vault credited to `to`
    */
    function deposit(address to, uint256 underlyingAmount) public virtual returns (uint256 shares);

    /**
      @notice Withdraw a specific amount of underlying tokens.
      @param to The address to receive underlying corresponding to the withdrawal.
      @param underlyingAmount The amount of the underlying token to withdraw.
      @return shares The shares in the vault burned from sender
    */
    function withdraw(address to, uint256 underlyingAmount) public virtual returns (uint256 shares);

    /**
      @notice Withdraw a specific amount of underlying tokens on behalf of `from`.
      @param from The address to debit shares from corresponding to the withdrawal.
      @param to The address to receive underlying corresponding to the withdrawal.
      @param underlyingAmount The amount of the underlying token to withdraw.
      @return shares The shares in the vault burned from `from`.
      @dev requires ERC-20 approval of the ERC-4626 shares by sender.
    */
    function withdrawFrom(
        address from,
        address to,
        uint256 underlyingAmount
    ) public virtual returns (uint256 shares);

    /**
      @notice Redeem a specific amount of shares for underlying tokens.
      @param to The address to receive underlying corresponding to the redemption.
      @param shareAmount The amount of shares to redeem.
      @return value The underlying amount transferred to `to`.
    */
    function redeem(address to, uint256 shareAmount) public virtual returns (uint256 value);

    /**
      @notice Redeem a specific amount of shares for underlying tokens on behalf of `from`.
      @param from The address to debit shares from corresponding to the redemption.
      @param to The address to receive underlying corresponding to the redemption.
      @param shareAmount The amount of shares to redeem.
      @return value The underlying amount transferred to `to`.
    */
    function redeemFrom(
        address from,
        address to,
        uint256 shareAmount
    ) public virtual returns (uint256 value);

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /** 
      @notice The underlying token the Vault accepts.
      @return the ERC20 underlying implementation address.
    */
    function underlying() public view virtual returns (ERC20);

    /** 
      @notice Returns a user's Vault balance in underlying tokens.
      @param user The user to get the underlying balance of.
      @return balance The user's Vault balance in underlying tokens.
    */
    function balanceOfUnderlying(address user) public view virtual returns (uint256 balance);

    /** 
      @notice Calculates the total amount of underlying tokens the Vault holds.
      @return totalUnderlyingHeld The total amount of underlying tokens the Vault holds.
    */
    function totalHoldings() public view virtual returns (uint256);

    /** 
      @notice Calculates the amount of shares corresponding to an underlying amount.
      @param underlyingAmount the amount of underlying tokens to convert to shares.
      @return shareAmount the amount of shares corresponding to a given underlying amount
    */
    function calculateShares(uint256 underlyingAmount) public view virtual returns (uint256 shareAmount);

    /** 
      @notice Calculates the amount of underlying corresponding to a share amount.
      @param shareAmount the amount of shares to convert to an underlying amount.
      @return underlyingAmount the amount of underlying corresponding to a given amount of shares.
    */
    function calculateUnderlying(uint256 shareAmount) public view virtual returns (uint256 underlyingAmount);
}
