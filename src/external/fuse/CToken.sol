// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {CERC20} from "libcompound/interfaces/CERC20.sol";

abstract contract CToken is CERC20 {
    function comptroller() virtual external view returns(address);
    function getCash() virtual external view returns(uint256);
}