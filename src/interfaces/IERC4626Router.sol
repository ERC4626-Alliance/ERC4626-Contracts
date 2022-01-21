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
     @notice deposit `amountUnderlying` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit underlying to.
     @param to The destination of ownership shares.
     @param amountUnderlying The amount of underlying to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `amountUnderlying` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to withdraw underlying from.
     @param toVault The ERC4626 vault to deposit underlying to.
     @param to The destination of ownership shares.
     @param amountUnderlying The amount of underlying to withdraw from fromVault.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function withdrawToVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit underlying to.
     @param to The destination of ownership shares.
     @param amountShares The amount of shares to redeem from fromVault.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function redeemToVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountShares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);
}
