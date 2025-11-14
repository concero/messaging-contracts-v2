// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

contract ConceroRouterBase is ConceroRouterTest {
    function setUp() public override {
        super.setUp();
    }

    /* setMaxValidatorsCount */

    function test_setMaxValidatorsCount_Success() public {
        uint16 newMaxCount = 50;

        vm.prank(s_deployer);
        s_conceroRouter.setMaxValidatorsCount(newMaxCount);

        assertEq(s_conceroRouter.getMaxValidatorsCount(), newMaxCount);
    }

    function test_setMaxValidatorsCount_RevertsIfNotOwner() public {
        vm.expectRevert();
        vm.prank(s_user);
        s_conceroRouter.setMaxValidatorsCount(50);
    }

    /* getMaxValidatorsCount */

    function test_getMaxValidatorsCount_ReturnsCorrectValue() public view {
        assertEq(s_conceroRouter.getMaxValidatorsCount(), MAX_CONCERO_VALIDATORS_COUNT);
    }
}
