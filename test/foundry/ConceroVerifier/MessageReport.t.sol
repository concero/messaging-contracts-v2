// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";
import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Constants} from "contracts/common/Constants.sol";
import {MockCLFReport} from "../scripts/MockCLFReport.s.sol";
import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Message as MessageLib, MessageConstants} from "contracts/common/libraries/Message.sol";

contract MessageReport is ConceroVerifierTest {
    bytes32 internal clfRequestId;

    uint256 internal constant CLIENT_MESSAGE_CONFIG =
        (uint256(DST_CHAIN_SELECTOR) << MessageConstants.OFFSET_DST_CHAIN) |
            (1 << MessageConstants.OFFSET_MIN_SRC_CONF) |
            (1 << MessageConstants.OFFSET_MIN_DST_CONF) |
            (0 << MessageConstants.OFFSET_RELAYER_CONF) |
            (0 << MessageConstants.OFFSET_CALLBACKABLE) |
            (uint256(VerifierTypes.FeeToken.native) << MessageConstants.OFFSET_FEE_TOKEN);

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

        VerifierTypes.MessageReportResult memory result;
        result.version = 1;
        result.reportType = VerifierTypes.CLFReportType.Message;
        result.operator = operator;
        result.internalMessageConfig = bytes32("internalMessageConfig");
        result.messageId = bytes32("messageId");
        result.messageHashSum = bytes32("messageHashSum");
        result.dstChainData = "dstChain"; // Example dynamic data.
        result.allowedOperators = new bytes[](1);
        result.allowedOperators[0] = abi.encodePacked(operator);

        bytes memory response = abi.encode(result);

        MockCLFReport mockClf = new MockCLFReport();
        MockCLFReport.ClfDonReportSubmission memory clfSubmission = mockClf.createMessageReport();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "");
        //
        //    // Verify request is no longer pending
        //    assertFalse(conceroVerifier.isPendingCLFRequest(clfRequestId));
        //
        //    // Verify operator earned fees
        //    uint256 expectedFees = Constants.OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD;
        //    assertEq(conceroVerifier.getOperatorFeesNative(operator), expectedFees);
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
