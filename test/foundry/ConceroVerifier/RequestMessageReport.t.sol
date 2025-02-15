// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";

import {Message as MessageLib} from "contracts/common/libraries/Message.sol";
import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";

contract RequestMessageReport is ConceroVerifierTest {
    function setUp() public virtual override {
        super.setUp();

        _setPriceFeeds();
        _setOperatorDeposits();
        _setOperatorIsRegistered();
    }

    function test_requestMessageReport() public returns (bytes32) {
        bytes32 messageId = bytes32(uint256(1));
        bytes32 messageHashSum = bytes32(uint256(2));
        uint256 internalMessageConfig = MessageLib.buildInternalMessageConfig(
            CLIENT_MESSAGE_CONFIG,
            SRC_CHAIN_SELECTOR
        );
        bytes memory srcChainData = new bytes(0);

        vm.prank(operator);
        bytes32 clfRequestId = conceroVerifier.requestMessageReport(
            internalMessageConfig,
            messageId,
            messageHashSum,
            srcChainData
        );

        bool isCLFRequestPending = conceroVerifier.getStorage(
            Namespaces.VERIFIER,
            VerifierSlots.pendingCLFRequests,
            clfRequestId
        ) == 1;

        assertTrue(isCLFRequestPending);

        return clfRequestId;
    }
}
