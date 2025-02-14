// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {CommonConstants} from "contracts/common/CommonConstants.sol";
import {Message as MessageLib} from "contracts/common/libraries/Message.sol";

import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";
import {MockCLFReport} from "../scripts/MockCLFReport.s.sol";

contract MessageReport is ConceroVerifierTest {
    bytes32 internal clfRequestId;

    function setUp() public override {
        super.setUp();

        _setPriceFeeds();
        _setOperatorFeesEarned();
        _setOperatorDeposits();
        _setOperatorIsAllowed();
    }

    function test_requestMessageReport() public returns (bytes32) {
        uint256 internalMessageConfig = MessageLib.buildInternalMessageConfig(
            CLIENT_MESSAGE_CONFIG,
            SRC_CHAIN_SELECTOR
        );

        VerifierTypes.MessageReportRequest memory request = VerifierTypes.MessageReportRequest({
            messageId: bytes32(uint256(1)),
            messageHashSum: bytes32(uint256(2)),
            internalMessageConfig: internalMessageConfig,
            srcChainData: new bytes(0),
            dstChainData: new bytes(0)
        });

        vm.prank(operator);
        clfRequestId = conceroVerifier.requestMessageReport(request);

        bool isCLFRequestPending = conceroVerifier.getStorage(
            Namespaces.VERIFIER,
            VerifierSlots.pendingCLFRequests,
            clfRequestId
        ) == 1;

        assertTrue(isCLFRequestPending);

        return clfRequestId;
    }

    function test_handleOracleFulfillment_messageReport() public {
        bytes32 clfRequestId = test_requestMessageReport();

        uint256 reportConfig = (uint256(uint8(CommonTypes.CLFReportType.Message)) << 248) |
            (uint256(1) << 240) |
            (uint256(uint160(operator)));

        CommonTypes.MessageReportResult memory result;
        result.reportConfig = reportConfig;
        result.internalMessageConfig = INTERNAL_MESSAGE_CONFIG;
        result.messageId = bytes32("messageId");
        result.messageHashSum = bytes32("messageHashSum");
        result.dstChainData = "dstChain";
        result.allowedOperators = new bytes[](1);
        result.allowedOperators[0] = abi.encodePacked(operator);

        bytes memory response = abi.encode(result);

        MockCLFReport mockClf = new MockCLFReport();
        RouterTypes.ClfDonReportSubmission memory clfSubmission = mockClf.createMessageReport();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "");
    }
}
//
//    function test_handleOracleFulfillment_WithError_messageReport() public {
//        // First request a message report
//        test_requestMessageReport();
//
//        // Create mock CLF report
//        MockCLFReport.ClfDonReportSubmission memory clfSubmission = MockCLFReport
//            .createMessageReport();
//
//        // Mock the router calling handleOracleFulfillment with error
//        vm.prank(address(clfRouter));
//        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "error");
//
//        // Verify request is no longer pending
//        assertFalse(conceroVerifier.isPendingCLFRequest(clfRequestId));
//
//        // Verify no fees were earned due to error
//        assertEq(conceroVerifier.getOperatorFeesNative(operator), 0);
//    }
//}
