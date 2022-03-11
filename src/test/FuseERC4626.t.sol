pragma solidity ^0.8.10;

import {Hevm} from "./Hevm.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {MockCToken} from "./mock/MockCToken.sol";
import {FuseERC4626} from "../vaults/fuse/FuseERC4626.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract TestFuseERC4626 {
    using FixedPointMathLib for uint256;

    MockERC20 private token;
    MockCToken private cToken;
    FuseERC4626 private vault;

    Hevm public constant vm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        token = new MockERC20();
        cToken = new MockCToken(address(token), false);
        vault = new FuseERC4626(address(cToken), "fTRIBE-8 ERC4626 wrapper", "4626-fTRIBE-8");
      
        vm.label(address(token), "token");
        vm.label(address(cToken), "cToken");
        vm.label(address(vault), "vault");
        vm.label(address(this), "user");
    }

    /*///////////////////////////////////////////////////////////////
                init
    //////////////////////////////////////////////////////////////*/

    function testInit() public view {
        // wrapper metadata
        require(address(vault.cToken()) == address(cToken));
        require(address(vault.cTokenUnderlying()) == address(token));
        
        // vault metadata
        require(address(vault.asset()) == address(token));
        require(vault.totalAssets() == 0);

        // balance checks
        require(token.balanceOf(address(this)) == 0);
        require(token.balanceOf(address(cToken)) == 0);
        require(vault.balanceOf(address(this)) == 0);
    }

    /*///////////////////////////////////////////////////////////////
                deposit()
    //////////////////////////////////////////////////////////////*/

    function testDeposit1(uint128 _assets) public {
        uint256 assets = uint256(_assets) + 1; // don't fuzz with 0
        address receiver = address(0x42);

        token.mint(address(this), assets);
        token.approve(address(vault), assets);
        uint256 expectedShares = vault.previewDeposit(assets);
        uint256 shares = vault.deposit(assets, receiver);
        require(shares == expectedShares);

        require(vault.totalAssets() == assets || vault.totalAssets() == assets - 1);
        require(token.balanceOf(address(this)) == 0);
        require(token.balanceOf(address(cToken)) == assets);
        require(vault.balanceOf(receiver) == expectedShares);
    }

    function testDeposit2() public {
        cToken.setError(true);
        token.mint(address(this), 1e18);
        token.approve(address(vault), 1e18);

        vm.expectRevert(bytes("MINT_FAILED"));
        vault.deposit(1e18, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                mint()
    //////////////////////////////////////////////////////////////*/

    function testMint1(uint128 _shares) public {
        uint256 shares = uint256(_shares) + 1; // don't fuzz with 0
        address receiver = address(0x42);

        uint256 expectedAssets = vault.previewMint(shares);
        token.mint(address(this), expectedAssets);
        token.approve(address(vault), expectedAssets);
        uint256 assets = vault.mint(shares, receiver);
        require(assets == expectedAssets);

        require(vault.totalAssets() == expectedAssets || vault.totalAssets() == expectedAssets - 1);
        require(token.balanceOf(address(this)) == 0);
        require(token.balanceOf(address(cToken)) == expectedAssets);
        require(vault.balanceOf(receiver) == shares);
    }

    function testMint2() public {
        cToken.setError(true);
        token.mint(address(this), 1e18);
        token.approve(address(vault), 1e18);

        vm.expectRevert(bytes("MINT_FAILED"));
        vault.mint(5e17, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                withdraw()
    //////////////////////////////////////////////////////////////*/

    function testWithdraw() public {
        uint256 assets = 1e18;
        address receiver = address(0x42);
        address owner = address(this);

        token.mint(owner, assets);
        token.approve(address(vault), assets);
        uint256 depositShares = vault.deposit(assets, owner);
        uint256 withdrawShares = vault.withdraw(assets, receiver, owner);
        require(withdrawShares == depositShares);

        require(vault.totalAssets() == 0);
        require(token.balanceOf(receiver) == assets);
        require(token.balanceOf(address(cToken)) == 0);
        require(vault.balanceOf(owner) == 0);
    }

    function testWithdraw2() public {
        address receiver = address(0x42);
        address owner = address(this);

        token.mint(owner, 1e18);
        token.approve(address(vault), 1e18);
        vault.deposit(1e18, owner);
        cToken.setError(true);

        vm.expectRevert(bytes("REDEEM_FAILED"));
        vault.withdraw(1e18, receiver, owner);
    }

    function testWithdraw3() public {
        address receiver = address(0x42);
        address owner = address(this);

        token.mint(owner, 1e18);
        token.approve(address(vault), 1e18);
        vault.deposit(1e18, owner);

        // panic code 11 Arithmetic over/underflow
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        vm.prank(receiver);
        vault.withdraw(1e18, receiver, owner);
    }

    /*///////////////////////////////////////////////////////////////
                redeem()
    //////////////////////////////////////////////////////////////*/

    function testRedeem1() public {
        address receiver = address(0x42);
        address owner = address(this);

        uint256 shares = 1e18;

        token.mint(owner, 1e18);
        token.approve(address(vault), 1e18);
        uint256 depositAssets = vault.mint(shares, owner);
        uint256 redeemAssets = vault.redeem(shares, receiver, owner);
        require(redeemAssets == depositAssets);

        require(vault.totalSupply() == 0);
        require(token.balanceOf(receiver) == 1e18);
        require(vault.balanceOf(owner) == 0);
    }

    function testRedeem2() public {
        address receiver = address(0x42);
        address owner = address(this);

        token.mint(owner, 1e18);
        token.approve(address(vault), 1e18);
        vault.mint(5e17, owner);
        cToken.setError(true);

        vm.expectRevert(bytes("REDEEM_FAILED"));
        vault.redeem(5e17, receiver, owner);
    }

    function testRedeem3() public {
        address receiver = address(0x42);
        address owner = address(this);

        token.mint(owner, 1e18);
        token.approve(address(vault), 1e18);
        vault.mint(5e17, owner);

        // panic code 11 Arithmetic over/underflow
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        vm.prank(receiver);
        vault.redeem(5e17, receiver, owner);
    }

    /*///////////////////////////////////////////////////////////////
                vault accounting viewers
    //////////////////////////////////////////////////////////////*/

    function testConvertToShares() public {
        uint256 assets = 1e18;
        uint256 expectedShares = assets; // 1:1 initially
        uint256 actual = vault.convertToShares(assets);
        require(actual == expectedShares);

        // first user enter the vault, ratio is 1:1
        token.mint(address(this), assets);
        token.approve(address(vault), assets);
        vault.deposit(assets, address(this));
        expectedShares = assets;
        actual = vault.convertToShares(assets);
        require(actual == expectedShares);

        // donate some cTokens to the vault
        token.mint(address(this), assets);
        token.approve(address(cToken), assets);
        cToken.mint(assets); // get some cTokens on the test contract
        cToken.transfer(address(vault), cToken.balanceOf(address(this))); // send cTokens to the vault
        
        // vault shares should now be worth 2 assets
        expectedShares = assets / 2; // 1:2
        actual = vault.convertToShares(assets);
        require(actual == expectedShares);
    }
    
    function testConvertToAssets() public {
        uint256 shares = 1e18;
        uint256 expectedAssets = shares; // 1:1 initially
        uint256 actual = vault.convertToAssets(shares);
        require(actual == expectedAssets);

        // first user enter the vault, ratio is 1:1
        token.mint(address(this), shares);
        token.approve(address(vault), shares);
        vault.deposit(shares, address(this));
        expectedAssets = shares;
        actual = vault.convertToAssets(shares);
        require(actual == expectedAssets);

        // donate some cTokens to the vault
        token.mint(address(this), shares);
        token.approve(address(cToken), shares);
        cToken.mint(shares); // get some cTokens on the test contract
        cToken.transfer(address(vault), cToken.balanceOf(address(this))); // send cTokens to the vault
        
        // vault shares should now be worth 2 assets
        expectedAssets = shares * 2; // 1:2
        actual = vault.convertToAssets(shares);
        require(actual == expectedAssets);
    }
    
    function testMaxDeposit() public view {
        address owner = address(0x42);
        uint256 expected = 100e18;
        uint256 actual = vault.maxDeposit(owner);
        require(actual == expected);
    }
    
    function testPreviewDeposit(uint128 assets) public view {
        uint256 expected = uint256(assets); // 1:1 initially
        uint256 actual = vault.previewDeposit(assets);
        require(actual == expected);
    }
    
    function testMaxMint() public view {
        address owner = address(0x42);
        uint256 expected = 100e18;
        uint256 actual = vault.maxMint(owner);
        require(actual == expected);
    }
    
    function testPreviewMint(uint128 shares) public view {
        uint256 expected = uint256(shares); // 1:1 initially
        uint256 actual = vault.previewMint(shares);
        require(actual == expected);
    }
    
    function testMaxWithdraw() public {
        address owner = address(0x42);
        require(vault.maxWithdraw(owner) == 0);
        token.mint(owner, 1e18);
        vm.prank(owner);
        token.approve(address(vault), 1e18);
        vm.prank(owner);
        vault.deposit(1e18, owner);
        require(vault.maxWithdraw(owner) == 1e18);
    }
    
    function testPreviewWithdraw(uint128 assets) public view {
        uint256 expected = assets; // 1:1 initially
        uint256 actual = vault.previewWithdraw(assets);
        require(actual == expected);
    }

    function testMaxRedeem() public {
        address owner = address(0x42);
        require(vault.maxRedeem(owner) == 0);
        token.mint(owner, 1e18);
        vm.prank(owner);
        token.approve(address(vault), 1e18);
        vm.prank(owner);
        vault.mint(1e17, owner);
        require(vault.maxRedeem(owner) == 1e17);
    }
    
    function testPreviewRedeem(uint128 shares) public view {
        uint256 expected = uint256(shares); // 1:1 initially
        uint256 actual = vault.previewRedeem(shares);
        require(actual == expected);
    }
}
