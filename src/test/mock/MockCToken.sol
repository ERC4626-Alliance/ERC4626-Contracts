// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {MockERC20} from "./MockERC20.sol";

interface CToken {
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}

contract MockCToken is MockERC20 {

    MockERC20 public token;
    bool public error;
    bool public isCEther;

    uint256 private constant EXCHANGE_RATE_SCALE = 1e18;
    uint256 public effectiveExchangeRate = 2e18;

    constructor(address _token, bool _isCEther) {
        token = MockERC20(_token);
        isCEther = _isCEther;
    }

    function setError(bool _error) external {
        error = _error;
    }

    function setEffectiveExchangeRate(uint256 _effectiveExchangeRate) external {
        effectiveExchangeRate = _effectiveExchangeRate;
    }

    function isCToken() external pure returns(bool) {
        return true;
    }

    function underlying() external view returns(address) {
        return address(token);
    }

    function mint() external payable {
        _mint(msg.sender, msg.value * EXCHANGE_RATE_SCALE / effectiveExchangeRate);
    }

    function mint(uint256 amount) external returns (uint) {
        token.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount * EXCHANGE_RATE_SCALE/ effectiveExchangeRate);
        return error ? 1 : 0;
    }

    function redeem(uint redeemTokens) external returns (uint) {
        _burn(msg.sender, redeemTokens);
        uint256 redeemAmount = redeemTokens * effectiveExchangeRate / EXCHANGE_RATE_SCALE;
        if (address(this).balance >= redeemAmount) {
            payable(msg.sender).transfer(redeemAmount);
        } else {
            token.transfer(msg.sender, redeemAmount);
        }
        return error ? 1 : 0;
    }
    
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        _burn(msg.sender, redeemAmount * EXCHANGE_RATE_SCALE / effectiveExchangeRate);
        if (address(this).balance >= redeemAmount) {
            payable(msg.sender).transfer(redeemAmount);
        } else {
            token.transfer(msg.sender, redeemAmount);
        }
        return error ? 1 : 0;
    }

    function exchangeRateStored() external view returns (uint) {
        return EXCHANGE_RATE_SCALE * effectiveExchangeRate / EXCHANGE_RATE_SCALE; // 2:1
    }

    function exchangeRateCurrent() external returns (uint) {
        // fake state operation to not allow "view" modifier
        effectiveExchangeRate = effectiveExchangeRate;
        
        return EXCHANGE_RATE_SCALE * effectiveExchangeRate / EXCHANGE_RATE_SCALE; // 2:1
    }

    function getCash() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function totalBorrows() external pure returns (uint) {
        return 0;
    }
}
