// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "solmate-next/mixins/ERC4626.sol";
import "solmate-next/auth/Auth.sol";

/// @title Tokenized Vault with a solmate Auth pattern
/// @author joeysantoro
contract AuthERC4626 is ERC4626, Auth {

    /// @notice Creates a new Vault that accepts a specific underlying token.
    /// @param _underlying The ERC20 compliant token the Vault should accept.
    /// @param _name The name for the vault token.
    /// @param _symbol The symbol for the vault token.
    /// @param _owner the owner of the Vault
    /// @param _authority the authority of the Vault
    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol,
        address _owner,
        Authority _authority
    ) ERC4626(_underlying, _name, _symbol) Auth(_owner, _authority) {}

    function deposit(address to, uint256 underlyingAmount) public override requiresAuth returns (uint256 shares) {
        return super.deposit(to, underlyingAmount);
    }
    
    function mint(address to, uint256 shareAmount) public override requiresAuth returns (uint256 underlyingAmount) {
        return super.mint(to, shareAmount);
    }

    function withdraw(address from, address to, uint256 underlyingAmount) public override requiresAuth returns (uint256 shares) {
        return super.withdraw(from, to, underlyingAmount);
    }
    
    function redeem(address from, address to, uint256 shareAmount) public override requiresAuth returns (uint256 underlyingAmount) {
        return super.redeem(from, to, shareAmount);
    }
}