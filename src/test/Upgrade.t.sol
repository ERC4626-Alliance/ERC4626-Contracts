pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Hevm} from "./Hevm.sol";

import {ConvexERC4626, IConvexBaseRewardPool, IConvexBooster} from "../vaults/convex/ConvexERC4626.sol";

interface FuseFeeDist {
    function _editCErc20DelegateWhitelist(address[] memory oldImplementations, address[] memory newImplementations, bool[] memory allowResign, bool[] memory statuses) external;

    function _callPool(address[] memory, bytes memory) external;
}

contract Upgrade is DSTestPlus {
    // vm used for cheating
    Hevm vm = Hevm(HEVM_ADDRESS);

    // FEI-3crv LP token
    address fei3crv = 0x06cb22615BA53E60D67Bf6C341a0fD5E718E1655;
    // FEI-3crv LP token CToken in Fuse pool 8
    address fei3crvFeiRari = 0xBFB6f7532d2DB0fE4D83aBb001c5C2B0842AF4dB;
    // FEI-3crv Curve Gauge
    address fei3crvGauge = 0xdC69D4cB5b86388Fff0b51885677e258883534ae;
    // ConvexERC4626 for FEI-3crv
    address newPlugin = 0x410bC78B149A3cdbF9d9739B161F75AfBc9E88BA;
    // CToken implementation that supports plugins (CErc20PluginDelegate)
    address CErc20PluginDelegate = 0xbfb8D550B53F64F581df1Da41DDa0CB9E596Aa0E;
    // Rari admin
    address fuseAdmin = 0x5eA4A9a7592683bF0Bc187d6Da706c6c4770976F;
    // Fuse fee distributor contract
    address fuseFeeDist = 0xa731585ab05fC9f83555cf9Bff8F58ee94e18F85;

    function setUp() public {
        vm.label(HEVM_ADDRESS, "vm");
        vm.label(fei3crv, "fei3crv");
        vm.label(fei3crvFeiRari, "fei3crvFeiRari");
        vm.label(fei3crvGauge, "fei3crvGauge");
        vm.label(newPlugin, "newPlugin");
        vm.label(CErc20PluginDelegate, "CErc20PluginDelegate");
        vm.label(fuseAdmin, "fuseAdmin");
        vm.label(fuseFeeDist, "fuseFeeDist");
        vm.label(address(this), "test");
    }

    function testUpgrade() public {
        // Start with ~191M LP tokens staked in the CToken
        require(ERC20(fei3crv).balanceOf(fei3crvFeiRari) > 150_000_000e18);
        // Less than 10M LP tokens staked on Curve gauge initially
        require(ERC20(fei3crvGauge).totalSupply() < 10_000_000e18);

        // Update CToken implementation
        address[] memory pools = new address[](1);
        pools[0] = address(fei3crvFeiRari);

        address[] memory impls = new address[](1);
        impls[0] = CErc20PluginDelegate;

        bool[] memory allowResign = new bool[](1);
        bool[] memory status = new bool[](1);
        status[0] = true;

        bytes memory data = abi.encodeWithSignature(
          "_setImplementationSafe(address,bool,bytes)",
          CErc20PluginDelegate,
          false,
          abi.encode(address(newPlugin))
        );
        //bytes memory data = hex"50d85b73000000000000000000000000bfb8d550b53f64f581df1da41dda0cb9e596aa0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000200000000000000000000000007ED904d3BE134b3C44dcBA0901A51C4eCDB364B1";
        vm.startPrank(fuseAdmin);
        FuseFeeDist(fuseFeeDist)._editCErc20DelegateWhitelist(impls, impls, allowResign, status);
        FuseFeeDist(fuseFeeDist)._callPool(pools, data);
        vm.stopPrank();

        // Should end with > 150M LP tokens staked in the Curve Gauge
        require(ERC20(fei3crvGauge).totalSupply() > 150_000_000e18);
        // Should end with assets staked in Convex through the ERC4626 plugin
        require(ERC4626(newPlugin).totalAssets() > 150_000_000e18);
    }
}