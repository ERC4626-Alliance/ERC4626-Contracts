// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./IERC4626.sol";

/** 
 @title ERC4626Router Interface
 @author joeysantoro
 @notice A canonical router between ERC4626 Vaults https://eips.ethereum.org/EIPS/eip-4626

 The router atomically executes user journeys to originate a vault position, or route between ERC4626 vault implementations for the same token.
 @dev the router makes no special considerations for unique ERC20 implementations such as fee on transfer. 
 There are no built in protections for unexpected behavior beyond enforcing the minSharesOut is received.
 */
interface IERC4626Router {
    /************************** Errors **************************/

    /// @notice thrown when amount of shares/underlying received is below the min set by caller
    error MinAmountError();

    /************************** Deposit **************************/
    
    /** 
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit underlying to.
     @param to The destination of ownership shares.
     @param amount The amount of underlying to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `amount` from an ERC4626 vault.
     @param vault The ERC4626 vault to withdraw underlying from.
     @param to The destination of underlying.
     @param amount The amount of underlying to withdraw from vault.
     @param minAmountOut The min amount of underlying received by `to`.
     @return amountOut the amount of underlying received by `to`.
     @dev throws MinOutError   
    */
    function withdrawFromVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);

    /** 
     @notice withdraw `amount` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to withdraw underlying from.
     @param toVault The ERC4626 vault to deposit underlying to.
     @param to The destination of ownership shares.
     @param amount The amount of underlying to withdraw from fromVault.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function withdrawToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` shares from an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param to The destination of underlying.
     @param shares The amount of shares to redeem from vault.
     @param minAmountOut The min amount of underlying received by `to`.
     @return amountOut the amount of underlying received by `to`.
     @dev throws MinOutError   
    */
    function redeemFromVault(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);


    /** 
     @notice redeem `shares` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit underlying to.
     @param to The destination of ownership shares.
     @param shares The amount of shares to redeem from fromVault.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function redeemToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);
}
