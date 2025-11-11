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

    /* setMaxMessageSize */

    function test_setMaxMessageSize_Success() public {
        uint64 newMaxSize = 2000000;

        vm.prank(s_deployer);
        s_conceroRouter.setMaxMessageSize(newMaxSize);

        assertEq(s_conceroRouter.getMaxPayloadSize(), newMaxSize);
    }

    function test_setMaxMessageSize_RevertsIfNotOwner() public {
        vm.expectRevert();
        vm.prank(s_user);
        s_conceroRouter.setMaxMessageSize(2000000);
    }

    /* setTokenPriceFeed */

    function test_setTokenPriceFeed_RevertsIfNotOwner() public {
        vm.expectRevert();
        vm.prank(s_user);
        s_conceroRouter.setTokenPriceFeed(address(0), makeAddr("newPriceFeed"));
    }

    /* getMaxPayloadSize */

    function test_getMaxPayloadSize_ReturnsCorrectValue() public view {
        assertEq(s_conceroRouter.getMaxPayloadSize(), MAX_CONCERO_MESSAGE_SIZE);
    }

    /* getMaxValidatorsCount */

    function test_getMaxValidatorsCount_ReturnsCorrectValue() public view {
        assertEq(s_conceroRouter.getMaxValidatorsCount(), MAX_CONCERO_VALIDATORS_COUNT);
    }
}
