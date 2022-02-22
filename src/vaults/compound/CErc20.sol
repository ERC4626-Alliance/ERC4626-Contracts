// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

abstract contract CErc20 is ERC20 {
    function underlying() external virtual returns (address);
    function mint(uint256 amount) external virtual returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);
    function redeem(uint256 redeemTokens) external virtual returns (uint256);
    function exchangeRateStored() external view virtual returns (uint256);
    function exchangeRateCurrent() external virtual returns (uint256);
    function isCToken() external view virtual returns(bool);
    function isCEther() external view virtual returns(bool);
    function getCash() external view virtual returns(uint256);
    function totalBorrows() external view virtual returns(uint256);
}
