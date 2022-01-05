// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

contract SampleContract {
    uint256 num2;

    function func1(uint256 num) external {
        num2 = num;

        for (uint256 i = 0; i < num; i++) {
            num2--;
        }

        assert(num2 == 0);
    }

    function func2(uint256 num) external {
        num2 = num;

        for (uint256 i = 0; i < num; i++) {
            num2--;
        }

        assert(num2 == 0);
    }
}
