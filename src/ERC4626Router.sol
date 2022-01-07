// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./interfaces/IERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title ERC4626Router contract
/// @author alcueca
contract ERC4626Router {
    using SafeTransferLib for ERC20;

    mapping (IERC4626 => bool) public vaults;
    mapping (IERC20 => bool) public tokens;

    /// @dev Allow operating with a vault and its underlying
    function addVault(IERC4626 vault, bool set)
        public
        auth
    {
        vaults[vault] = set;
        tokens[IERC20(address(vault))] = set;
        tokens[vault.underlying()] = set;
        emit VaultAdded(vault, set);
    }

    /// @dev Execute a number of encoded calls in a single transaction
    function batch(bytes[] calldata calls)
        external
        returns(bytes[] memory results)
    {
        results = new bytes[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
            results[i] = result;
        }
    }

    /// @dev Execute any function on a vault, as an encoded call
    function route(IERC4626 vault, bytes calldata data)
        external
        returns (bytes memory result)
    {
        if (vaults(vault) != true) {
            revert VaultNotKnownError();
        }
        bool success;
        (success, result) = address(vault).call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }

    /// @dev Deposit underlying to a vault
    /// The underlying must have been transferred to the vault with `router.transfer` beforehand
    function deposit(
        IERC4626 vault,
        address to,
        uint256 amountIn,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut) {
        if (vaults(vault) != true) {
            revert VaultNotKnownError();
        }
        sharesOut = vault.deposit(to, amountIn);
        if (sharesOut <= minSharesOut) {
            revert MinAmountError();
        }
    }

    /// @dev Withdraw underlying from a vault
    /// The exact shares must have been transferred to the vault with `router.transfer` beforehand
    /// Alternatively, surplus shares can be sent, and then the remainder retrieved wih `router.route(vault.skim(...))`
    function withdraw(
        IERC4626 vault,
        address to,
        uint256 amountUnderlying,
        uint256 maxSharesIn
    ) external returns (uint256 sharesIn) {
        if (vaults(vault) != true) {
            revert VaultNotKnownError();
        }
        sharesIn = vault.withdraw(to, amountUnderlying);
        if (sharesIn <= maxSharesIn) {
            revert MaxAmountError();
        }
    }

    /// @dev Mint vault shares with underlying
    /// The exact underlying must have been transferred to the vault with `router.transfer` beforehand
    /// Alternatively, surplus underlying can be sent, and then the remainder retrieved wih `router.route(vault.skim(...))`
    function mint(
        IERC4626 vault,
        address to,
        uint256 amountShares,
        uint256 maxUnderlyingIn
    ) external returns (uint256 underlyingIn) {
        if (vaults(vault) != true) {
            revert VaultNotKnownError();
        }
        underlyingIn = vault.mint(to, amountShares);
        if (underlyingIn <= maxUnderlyingIn) {
            revert MaxAmountError();
        }
    }

    /// @dev Burn vault shares and receive underlying
    /// The shares must have been transferred to the vault with `router.transfer` beforehand
    function burn(
        IERC4626 vault,
        address to,
        uint256 amountShares,
        uint256 minUnderlyingOut
    ) external returns (uint256 underlyingOut) {
        if (vaults(vault) != true) {
            revert VaultNotKnownError();
        }
        underlyingOut = vault.burn(to, amountShares);
        if (underlyingOut >= minUnderlyingIn) {
            revert MinAmountError();
        }
    }

    /// @dev Execute an ERC2612 permit for the selected token
    function forwardPermit(IERC2612 token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(tokens[address(token)], "Unknown token");
        token.permit(msg.sender, spender, amount, deadline, v, r, s);
    }

    /// @dev Execute a Dai-style permit for the selected token
    function forwardDaiPermit(DaiAbstract token, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(tokens[address(token)], "Unknown token");
        token.permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
    }

    /// @dev Allow users to trigger a token transfer from themselves to a receiver through the ladle, to be used with batch
    function transfer(IERC20 token, address receiver, uint128 wad)
        external
    {
        require(tokens[address(token)], "Unknown token");
        token.safeTransferFrom(msg.sender, receiver, wad);
    }
}
