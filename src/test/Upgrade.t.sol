pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

import {ConvexERC4626, IConvexBaseRewardPool, IConvexBooster} from "../vaults/convex/ConvexERC4626.sol";

interface FuseFeeDist {
    function _editCErc20DelegateWhitelist(address[] memory oldImplementations, address[] memory newImplementations, bool[] memory allowResign, bool[] memory statuses) external;

    function _callPool(address[] memory, bytes memory) external;
}

contract Upgrade is DSTestPlus {

    ERC4626 oldPlugin = ERC4626(0xE5Af1Ac8B9b2c1e1912a051Da12C48f25b771b1d);

    ERC20 d3 = ERC20(0xBaaa1F5DbA42C3389bDbc2c9D2dE134F5cD0Dc89);

    address convex = 0x16C2beE6f55dAB7F494dBa643fF52ef2D47FBA36;

    address fD3 = 0x5cA8Ffe4DAD9452ED880FA429DD0A08574225936;

    FuseFeeDist admin = FuseFeeDist(0xa731585ab05fC9f83555cf9Bff8F58ee94e18F85);

    function testUpgrade() public {
        ERC20[] memory rewards = new ERC20[](2);
        rewards[0] = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
        rewards[1] = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

        ERC4626 plugin = new ConvexERC4626(
            d3,
            "d3 Convex Plugin",
            "d3CVX",
            IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31),
            IConvexBaseRewardPool(0x329cb014b562d5d42927cfF0dEdF4c13ab0442EF),
            0x5ae217dE26f6Ff5F481C6e10ec48b2cf2fc857C8,
            rewards
        );

        address[] memory pools = new address[](1);
        pools[0] = fD3;

        address[] memory impls = new address[](1);
        impls[0] = 0xbfb8D550B53F64F581df1Da41DDa0CB9E596Aa0E;

        bool[] memory allowResign = new bool[](1);
        bool[] memory status = new bool[](1);
        status[0] = true;

        bytes memory data = abi.encodeWithSignature("_setImplementationSafe(address,bool,bytes)", 0xbfb8D550B53F64F581df1Da41DDa0CB9E596Aa0E, false, abi.encode(address(plugin)));
        hevm.startPrank(0x5eA4A9a7592683bF0Bc187d6Da706c6c4770976F);
        admin._editCErc20DelegateWhitelist(impls, impls, allowResign, status);
        admin._callPool(pools, data);

        require(plugin.totalAssets() > 30_000_000e18, "totalAssets");
        require(oldPlugin.totalAssets() == 0, "old empty");
    }
}