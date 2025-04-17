// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
//
//import {CommonErrors} from "contracts/common/CommonErrors.sol";
//import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
//import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
//
//import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";
//
//contract SupportedChains is ConceroVerifierTest {
//    uint24[] public initialChainSelectors;
//    bool[] public initialSupportStatus;
//
//    function setUp() public override {
//        super.setUp();
//
//        initialChainSelectors = new uint24[](3);
//        initialChainSelectors[0] = 1;
//        initialChainSelectors[1] = 2;
//        initialChainSelectors[2] = 3;
//
//        initialSupportStatus = new bool[](3);
//        initialSupportStatus[0] = true;
//        initialSupportStatus[1] = true;
//        initialSupportStatus[2] = true;
//    }
//
//    function test_setSupportedChains() public {
//        vm.startPrank(deployer);
//
//        conceroVerifier.setSupportedChains(initialChainSelectors, initialSupportStatus);
//
//        for (uint256 i = 0; i < initialChainSelectors.length; i++) {
//            assertTrue(
//                conceroVerifier.isChainSupported(initialChainSelectors[i]),
//                "Chain should be supported"
//            );
//        }
//
//        uint24[] memory supportedChains = conceroVerifier.getSupportedChains();
//        assertEq(
//            supportedChains.length,
//            initialChainSelectors.length,
//            "Supported chains array length mismatch"
//        );
//
//        for (uint256 i = 0; i < supportedChains.length; i++) {
//            bool found = false;
//            for (uint256 j = 0; j < initialChainSelectors.length; j++) {
//                if (supportedChains[i] == initialChainSelectors[j]) {
//                    found = true;
//                    break;
//                }
//            }
//            assertTrue(found, "Chain selector not found in supported chains");
//        }
//
//        vm.stopPrank();
//    }
//
//    function test_setSupportedChains_RemoveChain() public {
//        vm.startPrank(deployer);
//
//        // First add chains
//        conceroVerifier.setSupportedChains(initialChainSelectors, initialSupportStatus);
//
//        // Now remove one chain
//        uint24[] memory updatedSelectors = new uint24[](1);
//        updatedSelectors[0] = initialChainSelectors[1];
//
//        bool[] memory updatedStatus = new bool[](1);
//        updatedStatus[0] = false;
//
//        conceroVerifier.setSupportedChains(updatedSelectors, updatedStatus);
//
//        // Chain 1 should still be supported
//        assertTrue(
//            conceroVerifier.isChainSupported(initialChainSelectors[0]),
//            "Chain 1 should still be supported"
//        );
//
//        // Chain 2 should not be supported
//        assertFalse(
//            conceroVerifier.isChainSupported(updatedSelectors[0]),
//            "Chain 2 should no longer be supported"
//        );
//
//        // Chain 3 should still be supported
//        assertTrue(
//            conceroVerifier.isChainSupported(initialChainSelectors[2]),
//            "Chain 3 should still be supported"
//        );
//
//        // Only 2 chains should be in the supported list now
//        uint24[] memory supportedChains = conceroVerifier.getSupportedChains();
//        assertEq(
//            supportedChains.length,
//            initialChainSelectors.length - 1,
//            "Supported chains count should be reduced by 1"
//        );
//
//        vm.stopPrank();
//    }
//
//    function test_setSupportedChains_AddAndRemove() public {
//        vm.startPrank(deployer);
//
//        // First add initial chains
//        conceroVerifier.setSupportedChains(initialChainSelectors, initialSupportStatus);
//
//        // Now add one new chain and remove two existing chains
//        uint24[] memory updatedSelectors = new uint24[](3);
//        updatedSelectors[0] = initialChainSelectors[0]; // remove
//        updatedSelectors[1] = initialChainSelectors[2]; // remove
//        updatedSelectors[2] = 4; // add new
//
//        bool[] memory updatedStatus = new bool[](3);
//        updatedStatus[0] = false;
//        updatedStatus[1] = false;
//        updatedStatus[2] = true;
//
//        conceroVerifier.setSupportedChains(updatedSelectors, updatedStatus);
//
//        // Chain 1 should not be supported
//        assertFalse(
//            conceroVerifier.isChainSupported(initialChainSelectors[0]),
//            "Chain 1 should no longer be supported"
//        );
//
//        // Chain 2 should still be supported
//        assertTrue(
//            conceroVerifier.isChainSupported(initialChainSelectors[1]),
//            "Chain 2 should still be supported"
//        );
//
//        // Chain 3 should not be supported
//        assertFalse(
//            conceroVerifier.isChainSupported(initialChainSelectors[2]),
//            "Chain 3 should no longer be supported"
//        );
//
//        // Chain 4 should be supported
//        assertTrue(
//            conceroVerifier.isChainSupported(updatedSelectors[2]),
//            "Chain 4 should be supported"
//        );
//
//        // 2 chains should be supported (Chain 2 and Chain 4)
//        uint24[] memory supportedChains = conceroVerifier.getSupportedChains();
//        assertEq(supportedChains.length, 2, "Should have exactly 2 supported chains");
//
//        vm.stopPrank();
//    }
//
//    function test_setSupportedChains_DoesNotDuplicateEntries() public {
//        vm.startPrank(deployer);
//
//        // First add chains
//        conceroVerifier.setSupportedChains(initialChainSelectors, initialSupportStatus);
//
//        // Now try to add one chain that is already supported
//        uint24[] memory duplicateSelectors = new uint24[](1);
//        duplicateSelectors[0] = initialChainSelectors[0];
//
//        bool[] memory duplicateStatus = new bool[](1);
//        duplicateStatus[0] = true;
//
//        conceroVerifier.setSupportedChains(duplicateSelectors, duplicateStatus);
//
//        // The supported chains count should not change
//        uint24[] memory supportedChains = conceroVerifier.getSupportedChains();
//        assertEq(
//            supportedChains.length,
//            initialChainSelectors.length,
//            "Supported chains count should not change when adding duplicates"
//        );
//
//        vm.stopPrank();
//    }
//
//    function test_setSupportedChains_WhenLengthMismatch_Reverts() public {
//        vm.startPrank(deployer);
//
//        uint24[] memory selectors = new uint24[](3);
//        selectors[0] = 1;
//        selectors[1] = 2;
//        selectors[2] = 3;
//
//        bool[] memory status = new bool[](2);
//        status[0] = true;
//        status[1] = true;
//
//        vm.expectRevert(CommonErrors.LengthMismatch.selector);
//        conceroVerifier.setSupportedChains(selectors, status);
//
//        vm.stopPrank();
//    }
//
//    function test_setSupportedChains_WhenNotOwner_Reverts() public {
//        vm.startPrank(operator);
//
//        uint24[] memory selectors = new uint24[](1);
//        selectors[0] = 1;
//
//        bool[] memory status = new bool[](1);
//        status[0] = true;
//
//        vm.expectRevert(CommonErrors.Unauthorized.selector);
//        conceroVerifier.setSupportedChains(selectors, status);
//
//        vm.stopPrank();
//    }
//
//    function test_isChainSupported_ReturnsFalseForUnknownChain() public {
//        assertFalse(conceroVerifier.isChainSupported(999), "Unknown chain should not be supported");
//    }
//
//    function test_getSupportedChains_EmptyByDefault() public {
//        uint24[] memory supportedChains = conceroVerifier.getSupportedChains();
//        assertEq(supportedChains.length, 0, "Supported chains should be empty by default");
//    }
//}
