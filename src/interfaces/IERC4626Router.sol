// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./IERC4626.sol";

/** 
 @title ERC4626Router Interface
 @author joeysantoro
 @notice Extends the ERC4626RouterBase with specific flows to save gas
 */
interface IERC4626Router {

    /************************** Deposit **************************/
    
    /** 
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /** 
     @notice deposit max assets to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinOutError   
    */
    function depositMax(
        IERC4626 vault, 
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `amount` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to withdraw assets from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to withdraw from fromVault.
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
    ) external payable returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit assets to.
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
    ) external payable returns (uint256 sharesOut);


    /** 
     @notice redeem max shares to an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param to The destination of assets.
     @param minAmountOut The min amount of assets received by `to`.
     @return amountOut the amount of assets received by `to`.
     @dev throws MinOutError   
    */
    function redeemMax(
        IERC4626 vault, 
        address to,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut);
}
