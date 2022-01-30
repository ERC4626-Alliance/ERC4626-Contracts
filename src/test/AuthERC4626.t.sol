// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {DSTestPlus} from "solmate-next/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate-next/test/utils/mocks/MockERC20.sol";

import {AuthERC4626, Authority} from "../vaults/AuthERC4626.sol";

import {Hevm} from "./Hevm.sol";

contract AuthERC4626Test is DSTestPlus {
    AuthERC4626 vault;
    MockERC20 token;

    Hevm vm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        token = new MockERC20("token", "TKN", 18);
        vault = new AuthERC4626(token, "token vault", "vTKN", address(this), Authority(address(0)));
    }

    function testWithdrawAuth() public {
        vm.prank(address(1));
        vm.expectRevert("UNAUTHORIZED");
        vault.withdraw(address(this), address(this), 0);
    }

    function testRedeemAuth() public {
        vm.prank(address(1));
        vm.expectRevert("UNAUTHORIZED");
        vault.redeem(address(this), address(this), 0);
    }

    function testDepositAuth() public {
        vm.prank(address(1));
        vm.expectRevert("UNAUTHORIZED");
        vault.deposit(address(this), 0);
    }

    function testMintAuth() public {
        vm.prank(address(1));
        vm.expectRevert("UNAUTHORIZED");
        vault.mint(address(this), 0);
    }
}
