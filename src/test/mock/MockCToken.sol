// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {MockERC20} from "./MockERC20.sol";
import {CERC20} from "libcompound/interfaces/CERC20.sol";
import {InterestRateModel} from "libcompound/interfaces/InterestRateModel.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockInterestRateModel is InterestRateModel {
    function getBorrowRate(
        uint256,
        uint256,
        uint256
    ) external view override returns (uint256) {
        return 0;
    }

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view override returns (uint256) {
        return 0;
    }
}

contract MockCToken is MockERC20, CERC20 {

    MockERC20 public token;
    bool public error;
    bool public isCEther;
    InterestRateModel public irm;

    uint256 private constant EXCHANGE_RATE_SCALE = 1e18;
    uint256 public effectiveExchangeRate = 2e18;

    constructor(address _token, bool _isCEther) {
        token = MockERC20(_token);
        isCEther = _isCEther;
        irm = new MockInterestRateModel();
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

    function underlying() external view override returns(ERC20) {
        return ERC20(address(token));
    }

    function balanceOfUnderlying(address) external view override returns(uint256) {
        return 0;
    }

    function mint() external payable {
        _mint(msg.sender, msg.value * EXCHANGE_RATE_SCALE / effectiveExchangeRate);
    }

    function mint(uint256 amount) external override returns (uint) {
        token.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount * EXCHANGE_RATE_SCALE / effectiveExchangeRate);
        return error ? 1 : 0;
    }

    function borrow(uint256) external override returns (uint256) {
        return 0;
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
    
    function redeemUnderlying(uint redeemAmount) external override returns (uint) {
        _burn(msg.sender, redeemAmount * EXCHANGE_RATE_SCALE / effectiveExchangeRate);
        if (address(this).balance >= redeemAmount) {
            payable(msg.sender).transfer(redeemAmount);
        } else {
            token.transfer(msg.sender, redeemAmount);
        }
        return error ? 1 : 0;
    }

    function exchangeRateStored() external view override returns (uint) {
        return EXCHANGE_RATE_SCALE * effectiveExchangeRate / EXCHANGE_RATE_SCALE; // 2:1
    }

    function exchangeRateCurrent() external override returns (uint) {
        // fake state operation to not allow "view" modifier
        effectiveExchangeRate = effectiveExchangeRate;
        
        return EXCHANGE_RATE_SCALE * effectiveExchangeRate / EXCHANGE_RATE_SCALE; // 2:1
    }

    function getCash() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function totalBorrows() external pure override returns (uint) {
        return 0;
    }

    function totalReserves() external pure override returns (uint) {
        return 0;
    }

    function totalFuseFees() external view override returns(uint256) {
        return 0;
    }

    function totalAdminFees() external view override returns(uint256) {
        return 0;
    }

    function interestRateModel() external view override returns(InterestRateModel) {
        return irm;
    }

    function reserveFactorMantissa() external view override returns(uint256) {
        return 0;
    }

    function fuseFeeMantissa() external view override returns(uint256) {
        return 0;
    }

    function adminFeeMantissa() external view override returns(uint256) {
        return 0;
    }

    function initialExchangeRateMantissa() external view override returns(uint256) {
        return 0;
    }

    function repayBorrow(uint256) external override returns (uint256) {
        return 0;
    }

    function repayBorrowBehalf(address, uint256) external override returns (uint256) {
        return 0;
    }

    function borrowBalanceCurrent(address) external override returns (uint256) {
        return 0;
    }

    function accrualBlockNumber() external view override returns (uint256) {
        return block.number;
    }
}
