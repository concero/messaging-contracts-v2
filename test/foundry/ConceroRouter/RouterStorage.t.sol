// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {GenericStorage} from "contracts/common/libraries/GenericStorage.sol";

import {RouterSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Storage as s, Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";

contract RouterStorage is ConceroRouterTest {
    function setUp() public override {
        super.setUp();
    }

    function test_SetAndGetNonce() public {
        uint256 newNonce = 123;

        vm.startPrank(deployer);
        conceroRouter.setStorage(Namespaces.ROUTER, RouterSlots.nonce, bytes32(0), newNonce);

        assertEq(
            conceroRouter.getStorage(Namespaces.ROUTER, RouterSlots.nonce, bytes32(0)),
            newNonce,
            "Storage getter failed for nonce"
        );
        vm.stopPrank();
    }

    function test_RevertInvalidStorageSlot() public {
        vm.expectRevert(GenericStorage.InvalidNamespace.selector);

        bytes32 invalidNamespace = keccak256("invalid.namespace");

        vm.prank(deployer);
        conceroRouter.setStorage(invalidNamespace, 0, bytes32(0), 1);
    }

    function test_RevertLengthMismatch() public {
        bytes32[] memory namespaces = new bytes32[](2);
        uint256[] memory offsets = new uint256[](2);
        bytes32[] memory mappingKeys = new bytes32[](1);
        uint256[] memory values = new uint256[](2);

        namespaces[0] = Namespaces.ROUTER;
        namespaces[1] = Namespaces.ROUTER;

        vm.expectRevert(CommonErrors.LengthMismatch.selector);

        vm.prank(deployer);
        conceroRouter.setStorageBulk(namespaces, offsets, mappingKeys, values);
    }

    function test_SetAndGetIsMessageProcessed() public {
        bytes32 messageId = keccak256("message123");
        bool isProcessed = true;

        vm.startPrank(deployer);

        conceroRouter.setStorage(
            Namespaces.ROUTER,
            RouterSlots.isMessageProcessed,
            messageId,
            isProcessed ? 1 : 0
        );

        assertEq(
            conceroRouter.getStorage(Namespaces.ROUTER, RouterSlots.isMessageProcessed, messageId),
            isProcessed ? 1 : 0,
            "Message processed status not set"
        );

        vm.stopPrank();
    }
}
