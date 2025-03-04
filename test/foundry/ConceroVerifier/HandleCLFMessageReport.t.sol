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
import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";
import {RequestMessageReport} from "./RequestMessageReport.t.sol";
import {IMockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";

contract HandleCLFMessageReport is RequestMessageReport {
    function setUp() public override {
        super.setUp();

        _setOperatorIsRegistered();
    }

    function test_handleOracleFulfillment_messageReport() public {
        bytes32 clfRequestId = test_requestMessageReport();

        MessageReport messageReport = new MessageReport();
        bytes memory clfResponse = messageReport.getResponse();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfResponse, "");
    }

    function test_handleOracleFulfillment_WithError_messageReport() public {
        bytes32 clfRequestId = test_requestMessageReport();

        MessageReport messageReport = new MessageReport();
        RouterTypes.ClfDonReportSubmission memory clfSubmission = messageReport.getReport();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "error");

        assertFalse(
            conceroVerifier.getStorage(
                Namespaces.VERIFIER,
                VerifierSlots.pendingCLFRequests,
                clfRequestId
            ) == 1
        );
        assertEq(conceroVerifier.getOperatorFeesEarned(operator), 0);
    }

    function test_handleOracleFulfillment_specificBytes_messageReport() public {
        // Known request ID from the transaction
        bytes32 clfRequestId = test_requestMessageReport();

        // Setup the necessary state to match the request
        address expectedOperator = address(0x4242424242424242424242424242424242424242);

        // Specific response bytes from the transaction
        bytes
            memory specificResponse = hex"000100000000000000000000424242424242424242424242424242424242424201000001000000000000010001000100000000000000000000000000000000001879c09c5539b8bbe4b454b9df0d2bbffa66ab2316ca38b9997de987f9b1b0b5acaf3289d7b601cbd114fb36c4d29c85bbfd5e133f14cb355c3fd8d99367964f00000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000ccccac597660eebf71b424415f874ee4c6b13d22000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000014eee38505c47acba0c866df7265bd3e25da596b27000000000000000000000000";

        // Execute the fulfillment
        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, specificResponse, "");

        // Verify the request was processed
        assertFalse(
            conceroVerifier.getStorage(
                Namespaces.VERIFIER,
                VerifierSlots.pendingCLFRequests,
                clfRequestId
            ) == 1
        );
    }

    function test_clfRouter_transmit_messageReport() public {
        // First, request a message report to set up the necessary state
        bytes32 clfRequestId = test_requestMessageReport();

        // Create a message report
        MessageReport messageReport = new MessageReport();
        RouterTypes.ClfDonReportSubmission memory clfSubmission = messageReport.getReport(
            clfRequestId
        );

        IMockCLFRouter(clfRouter).transmit(
            clfSubmission.context,
            clfSubmission.report,
            clfSubmission.rs,
            clfSubmission.ss,
            clfSubmission.rawVs
        );

        assertFalse(
            conceroVerifier.getStorage(
                Namespaces.VERIFIER,
                VerifierSlots.pendingCLFRequests,
                clfRequestId
            ) == 1
        );
    }
}

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
