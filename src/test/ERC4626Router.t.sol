pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "./mock/MockERC4626.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import {IWETH9, IERC4626Router, ERC4626Router, ERC4626RouterBase, IERC4626, SelfPermit, PeripheryPayments} from "../ERC4626Router.sol";

import {Hevm} from "./Hevm.sol";

contract ERC4626Test {

    MockERC20 underlying;
    IERC4626 vault;
    IERC4626 toVault;
    ERC4626Router router;
    IWETH9 weth;
    IERC4626 wethVault;

    bytes32 public PERMIT_TYPEHASH = keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            );

    Hevm VM = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    receive() external payable {}
    
    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        vault = IERC4626(address(new MockERC4626(underlying)));
        toVault = IERC4626(address(new MockERC4626(underlying)));

        weth = IWETH9(address(new WETH()));

        wethVault = IERC4626(address(new MockERC4626(weth)));

        router = new ERC4626Router("", weth); // empty reverse ens

        underlying.mint(address(this), 1e18);
    }

    function testMint() public {
        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);
    
        router.pullToken(underlying, 1e18, address(router));

        router.mint(IERC4626(address(vault)), address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testDeposit() public {

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);
    
        router.pullToken(underlying, 1e18, address(router));

        router.deposit(IERC4626(address(vault)), address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testDepositMax() public {
        underlying.mint(address(this), 2e18);

        underlying.approve(address(router), 3e18);

        router.approve(underlying, address(vault), 3e18);
    
        router.depositMax(IERC4626(address(vault)), address(this), 3e18);

        require(vault.balanceOf(address(this)) == 3e18);
        require(underlying.balanceOf(address(this)) == 0);
    }
    
    function testDepositToVault() public {

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

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
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        underlying.permit(owner, address(router), 1e18, block.timestamp, v, r, s);

        router.approve(underlying, address(vault), 1e18);

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
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector(SelfPermit.selfPermit.selector, underlying, 1e18, block.timestamp, v, r, s);
        data[1] = abi.encodeWithSelector(PeripheryPayments.approve.selector, underlying, address(vault), 1e18);
        data[2] = abi.encodeWithSelector(IERC4626Router.depositToVault.selector, vault, owner, 1e18, 1e18);

        VM.prank(owner);
        router.multicall(data);

        require(vault.balanceOf(owner) == 1e18);
        require(underlying.balanceOf(owner) == 0);
    }

    function testDepositTo() public {
        address to = address(1);

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), to, 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 0);
        require(vault.balanceOf(to) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testDepositBelowMinOutReverts() public {
        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        try router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testWithdrawToDeposit() public {
        underlying.approve(address(router), type(uint).max);

        router.approve(underlying, address(vault), 1e18);
        router.approve(underlying, address(toVault), 1e18);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        router.withdrawToDeposit(vault, toVault, address(this), 1e18, 1e18);

        require(toVault.balanceOf(address(this)) == 1e18);
        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testWithdrawToBelowMinOutReverts() public {
        underlying.approve(address(router), type(uint).max);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        try router.withdrawToDeposit(vault, toVault, address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testRedeemTo() public {
        underlying.approve(address(router), type(uint).max);

        router.approve(underlying, address(vault), 1e18);
        router.approve(underlying, address(toVault), 1e18);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        router.redeemToDeposit(vault, toVault, address(this), 1e18, 1e18);

        require(toVault.balanceOf(address(this)) == 1e18);
        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testRedeemToBelowMinOutReverts() public {
        underlying.approve(address(router), type(uint).max);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 1e18);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint).max);

        try router.redeemToDeposit(vault, toVault, address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testWithdraw() public {

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        vault.approve(address(router), 1e18);
        router.withdraw(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 1e18);
    }

    function testWithdrawWithPermit() public {
        uint256 privateKey = 0xBEEF;
        address owner = VM.addr(privateKey);

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), owner, 1e18, 1e18);

        (uint8 v, bytes32 r, bytes32 s) = VM.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        vault.permit(owner, address(router), 1e18, block.timestamp, v, r, s);

        VM.prank(owner);
        router.withdraw(vault, owner, 1e18, 1e18);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == 1e18);
    }

    function testWithdrawWithPermitViaMulticall() public {
        uint256 privateKey = 0xBEEF;
        address owner = VM.addr(privateKey);

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), owner, 1e18, 1e18);

        (uint8 v, bytes32 r, bytes32 s) = VM.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(SelfPermit.selfPermit.selector, vault, 1e18, block.timestamp, v, r, s);
        data[1] = abi.encodeWithSelector(IERC4626Router.withdraw.selector, vault, owner, 1e18, 1e18);

        VM.prank(owner);
        router.multicall(data);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == 1e18);
    }

    function testWithdrawBelowMinOutReverts() public {
        underlying.approve(address(router), 1e18);
        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        vault.approve(address(router), 1e18);
        try router.withdraw(IERC4626(address(vault)), address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testRedeem() public {

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        vault.approve(address(router), 1e18);
        router.redeem(vault, address(this), 1e18, 1e18);

        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 1e18);
    }

    function testRedeemMax() public {

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        vault.approve(address(router), 1e18);
        router.redeemMax(vault, address(this), 1e18);

        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 1e18);
    }

    function testRedeemWithPermit() public {
        uint256 privateKey = 0xBEEF;
        address owner = VM.addr(privateKey);

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), owner, 1e18, 1e18);

        (uint8 v, bytes32 r, bytes32 s) = VM.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        vault.permit(owner, address(router), 1e18, block.timestamp, v, r, s);

        VM.prank(owner);
        router.redeem(vault, owner, 1e18, 1e18);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == 1e18);
    }

    function testRedeemWithPermitViaMulticall() public {
        uint256 privateKey = 0xBEEF;
        address owner = VM.addr(privateKey);

        underlying.approve(address(router), 1e18);

        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), owner, 1e18, 1e18);

        (uint8 v, bytes32 r, bytes32 s) = VM.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), 1e18, 0, block.timestamp))
                )
            )
        );

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(SelfPermit.selfPermit.selector, vault, 1e18, block.timestamp, v, r, s);
        data[1] = abi.encodeWithSelector(IERC4626Router.redeem.selector, vault, owner, 1e18, 1e18);

        VM.prank(owner);
        router.multicall(data);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == 1e18);
    }

    function testRedeemBelowMinOutReverts() public {
        underlying.approve(address(router), 1e18);
        
        router.approve(underlying, address(vault), 1e18);

        router.depositToVault(IERC4626(address(vault)), address(this), 1e18, 1e18);

        vault.approve(address(router), 1e18);
        try router.redeem(IERC4626(address(vault)), address(this), 1e18, 1.1e18) {
            revert("fail");
        } catch {
            // success
        }
    }

    function testDepositETHToWETHVault() public {
        router.approve(weth, address(wethVault), 1 ether);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(PeripheryPayments.wrapWETH9.selector);
        data[1] = abi.encodeWithSelector(ERC4626RouterBase.deposit.selector, wethVault, address(this), 1e18, 1e18);

        router.multicall{value: 1 ether}(data);

        require(wethVault.balanceOf(address(this)) == 1e18);
        require(weth.balanceOf(address(router)) == 0);
    }

    function testWithdrawETHFromWETHVault() public {

        uint balanceBefore = address(this).balance;

        router.approve(weth, address(wethVault), 1 ether);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(PeripheryPayments.wrapWETH9.selector);
        data[1] = abi.encodeWithSelector(ERC4626RouterBase.deposit.selector, wethVault, address(this), 1e18, 1e18);

        router.multicall{value: 1 ether}(data);

        wethVault.approve(address(router), 1 ether);

        bytes[] memory withdrawData = new bytes[](2);
        withdrawData[0] = abi.encodeWithSelector(ERC4626RouterBase.withdraw.selector, wethVault, address(router), 1e18, 1e18);
        withdrawData[1] = abi.encodeWithSelector(PeripheryPayments.unwrapWETH9.selector, 1 ether, address(this));

        router.multicall(withdrawData);

        require(wethVault.balanceOf(address(this)) == 0);
        require(address(this).balance == balanceBefore);
    }
}
