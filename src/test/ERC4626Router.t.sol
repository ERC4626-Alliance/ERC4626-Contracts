pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate-next/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "./mock/MockERC4626.sol";

import {IERC4626Router, ERC4626Router, IERC4626, SelfPermit} from "../ERC4626Router.sol";

import {Hevm} from "./Hevm.sol";

contract ERC4626Test {

    MockERC20 underlying;
    IERC4626 vault;
    IERC4626 toVault;
    ERC4626Router router;

    Hevm VM = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        vault = IERC4626(address(new MockERC4626(underlying)));
        toVault = IERC4626(address(new MockERC4626(underlying)));

        router = new ERC4626Router(""); // empty reverse ens

        underlying.mint(address(this), 1e18);
    }

    function testDeposit() public {

        underlying.approve(address(router), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testDepositWithPermit() public {
        uint256 privateKey = 0xBEEF;
        address owner = VM.addr(privateKey);

        underlying.mint(owner, 1e18);

        (uint8 v, bytes32 r, bytes32 s) = VM.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    underlying.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(underlying.PERMIT_TYPEHASH(), owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        underlying.permit(owner, address(router), 1e18, block.timestamp, v, r, s);

        VM.prank(owner);
        router.depositToVault(vault, owner, 1e18, 1e18);

        require(vault.balanceOf(owner) == 1e18);
        require(underlying.balanceOf(owner) == 0);
    }

    function testDepositWithPermitViaMulticall() public {
        uint256 privateKey = 0xBEEF;
        address owner = VM.addr(privateKey);

        underlying.mint(owner, 1e18);

        (uint8 v, bytes32 r, bytes32 s) = VM.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    underlying.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(underlying.PERMIT_TYPEHASH(), owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(SelfPermit.selfPermit.selector, underlying, 1e18, block.timestamp, v, r, s);
        data[1] = abi.encodeWithSelector(IERC4626Router.depositToVault.selector, vault, owner, 1e18, 1e18);

        VM.prank(owner);
        router.multicall(data);

        require(vault.balanceOf(owner) == 1e18);
        require(underlying.balanceOf(owner) == 0);
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
