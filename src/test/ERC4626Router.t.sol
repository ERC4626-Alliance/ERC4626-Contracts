pragma solidity 0.8.10;

import {MockERC20} from "solmate-next/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "./mock/MockERC4626.sol";

import {IERC4626Router, ERC4626Router, IERC4626} from "../ERC4626Router.sol";

contract ERC4626Test {

    MockERC20 underlying;
    IERC4626 vault;
    IERC4626 toVault;
    ERC4626Router router;

    error MinAmountError();

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        vault = IERC4626(address(new MockERC4626(underlying)));
        toVault = IERC4626(address(new MockERC4626(underlying)));

        router = new ERC4626Router();

        underlying.mint(address(this), 1e18);
    }

    function testDeposit() public {

        underlying.approve(address(router), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testDepositTo() public {
        address to = address(1);

        underlying.approve(address(router), 1e18);

        router.depositToVault(IERC4626(address(vault)), to, 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 0);
        require(vault.balanceOf(to) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testDepositBelowMinOutReverts() public {
        underlying.approve(address(router), 1e18);

        try router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testWithdrawTo() public {
        underlying.approve(address(router), type(uint).max);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        router.withdrawToVault(vault, toVault, address(this), 1e18, 1e18);

        require(toVault.balanceOf(address(this)) == 1e18);
        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testWithdrawToBelowMinOutReverts() public {
        underlying.approve(address(router), type(uint).max);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        try router.withdrawToVault(vault, toVault, address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testRedeemTo() public {
        underlying.approve(address(router), type(uint).max);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        router.redeemToVault(vault, toVault, address(this), 1e18, 1e18);

        require(toVault.balanceOf(address(this)) == 1e18);
        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testRedeemToBelowMinOutReverts() public {
        underlying.approve(address(router), type(uint).max);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        try router.redeemToVault(vault, toVault, address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }
}
