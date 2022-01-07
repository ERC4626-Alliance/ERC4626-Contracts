// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./IERC4626.sol";

/** 
 @title ERC4626Router Interface
 @author joeysantoro
 @notice A canonical router between ERC4626 Vaults <link ERC>

 There are 2 types of Vaults with different access paterns:
  * "Approve Vaults" which use ERC20 approval to transferFrom the sender to the vault. e.g. Compound cToken
  * "Optimistic Vaults" which use internal accounting to grant ownership based on new underlying sent to the contract. e.g. Uniswap V2

 The router atomically executes user journeys to originate/close a vault position, or route between ERC4626 vault implementations for the same token.
 @dev the router makes no special considerations for unique ERC20 implementations such as fee on transfer. 
 There are no built in protections for unexpected behavior beyond enforcing the minSharesOut is received.
 */
interface IERC4626Router {
    /************************** Errors **************************/

    /// @notice thrown when amount of shares/underlying received is below the min set by caller
    error MinAmountError();

    /// @notice thrown when fromVault's underlying is not equal to toVault's underlying
    error UnderlyingMismatchError();

    /************************** Deposit **************************/

    /** 
     @notice deposit underlying to an "Approve Vault"
     @param vault The ERC4626 vault to deposit shares to
     @param to The destination of ownership shares
     @param amountIn The amount of underlying to transfer to the vault
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError
    */
    function depositToApproveVault(
        IERC4626 vault,
        address to,
        uint256 amountIn,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /** 
     @notice deposit underlying to an "Optimistic Vault"
     @param vault The ERC4626 vault to deposit shares to
     @param to The destination of ownership shares
     @param amountIn The amount of underlying to transfer to the vault
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError    
    */
    function depositToOptimisticVault(
        IERC4626 vault,
        address to,
        uint256 amountIn,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `underlying` to an Approve Vault.
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountUnderlying The amount underlying to withdraw and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function withdrawToApproveVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /** 
     @notice withdraw `underlying` to an Approve Vault.
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountUnderlying The amount underlying to withdraw and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function withdrawToOptimisticVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` to an Approve Vault.
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountShares The amount of shares to redeem and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function redeemToApproveVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountShares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /** 
     @notice redeem `shares` to an Optimistic Vault.
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountShares The amount of shares to redeem and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function redeemToOptimisticVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountShares,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    /*/////////////////////////////////////////////////////////////
                            Permit Implementations
    /////////////////////////////////////////////////////////////*/

    /************************** Deposit **************************/

    /** 
     @notice deposit underlying to an "Approve Vault" using EIP-2612 permit
     @param vault The ERC4626 vault to deposit shares to
     @param to The destination of ownership shares
     @param amountIn The amount of underlying to transfer to the vault
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError
    */
    function depositWithPermitToApproveVault(
        IERC4626 vault,
        address to,
        uint256 amountIn,
        uint256 minSharesOut,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 sharesOut);

    /** 
     @notice deposit underlying to an "Optimistic Vault" using EIP-2612 permit
     @param vault The ERC4626 vault to deposit shares to
     @param to The destination of ownership shares
     @param amountIn The amount of underlying to transfer to the vault
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError    
    */
    function depositWithPermitToOptimisticVault(
        IERC4626 vault,
        address to,
        uint256 amountIn,
        uint256 minSharesOut,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `underlying` to an Approve Vault using EIP-2612 permit
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountUnderlying The amount underlying to withdraw and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function withdrawWithPermitToApproveVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 sharesOut);

    /** 
     @notice withdraw `underlying` to an Approve Vault using EIP-2612 permit
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountUnderlying The amount underlying to withdraw and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function withdrawWithPermitToOptimisticVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountUnderlying,
        uint256 minSharesOut,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` to an Approve Vault using EIP-2612 permit
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountShares The amount of shares to redeem and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function redeemWithPermitToApproveVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountShares,
        uint256 minSharesOut,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 sharesOut);

    /** 
     @notice redeem `shares` to an Optimistic Vault using EIP-2612 permit
     @param fromVault The ERC4626 vault to withdraw underlying from
     @param toVault The ERC4626 vault to deposit underlying to
     @param to The destination of ownership shares
     @param amountShares The amount of shares to redeem and deposit
     @param minSharesOut The min amount of shares received by `to`
     @return sharesOut the amount of shares received by `to`
     @dev throws MinOutError, UnderlyingMismatchError   
    */
    function redeemWithPermitToOptimisticVault(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amountShares,
        uint256 minSharesOut,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 sharesOut);
}
