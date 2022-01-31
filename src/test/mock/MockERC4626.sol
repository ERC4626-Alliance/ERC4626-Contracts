// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

contract MockERC4626 is ERC4626 {

    constructor(ERC20 underlying) ERC4626(underlying, "MockVault", "MV") {}
}
