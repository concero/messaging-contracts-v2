// SPDX-License-Identifier: UNLICENSED
/* solhint-disable func-name-mixedcase */
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";

import {Errors} from "contracts/ConceroValidator/libraries/Errors.sol";
import {CLFRequestError} from "contracts/interfaces/IConceroValidator.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";

import {Types as ValidatorTypes} from "contracts/ConceroValidator/libraries/Types.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";
import {RequestMessageReportTest} from "./RequestMessageReport.t.sol";
import {IMockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";

contract HandleCLFMessageReportTest is RequestMessageReportTest {
    function setUp() public override {
        super.setUp();
    }

    function test_handleOracleFulfillment_EmitsRequestFulfilled() public {
        bytes32 clfRequestId = test_requestMessageReport();

        MessageReport messageReport = new MessageReport();
        bytes memory clfResponse = messageReport.getResponse();

        vm.expectEmit(true, false, false, false);
        emit FunctionsClient.RequestFulfilled(clfRequestId);

        vm.prank(address(clfRouter));
        conceroValidator.handleOracleFulfillment(clfRequestId, clfResponse, "");
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

        assertTrue(
            conceroValidator.getClfRequestIdStatus(clfRequestId) ==
                ValidatorTypes.CLFRequestStatus.Fulfilled
        );
    }

    function test_handleOracleFulfillment_WithError() public {
        bytes32 clfRequestId = test_requestMessageReport();

        bytes memory errorMessage = "CLF execution failed";

        vm.expectEmit(false, false, false, true);
        emit CLFRequestError(errorMessage);

        vm.prank(address(clfRouter));
        conceroValidator.handleOracleFulfillment(clfRequestId, "", errorMessage);

        // Request status should be Failed
        assertEq(
            uint256(conceroValidator.getClfRequestIdStatus(clfRequestId)),
            uint256(ValidatorTypes.CLFRequestStatus.Failed)
        );
    }

    function test_handleOracleFulfillment_InvalidClfRequestId() public {
        bytes32 invalidClfRequestId = bytes32(uint256(999));
        bytes memory response = "";

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidClfRequestId.selector, invalidClfRequestId)
        );

        vm.prank(address(clfRouter));
        conceroValidator.handleOracleFulfillment(invalidClfRequestId, response, "");
    }

    function test_handleOracleFulfillment_InvalidResultType_Unknown() public {
        bytes32 clfRequestId = test_requestMessageReport();

        // Create response with Unknown type (invalid for Validator)
        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Unknown,
            payloadVersion: 1,
            requester: address(0)
        });

        bytes memory invalidResponse = abi.encode(resultConfig, bytes(""));

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidClfResultType.selector));

        vm.prank(address(clfRouter));
        conceroValidator.handleOracleFulfillment(clfRequestId, invalidResponse, "");
    }

    function test_handleOracleFulfillment_InvalidMessageVersion() public {
        bytes32 clfRequestId = test_requestMessageReport();

        // Create response with invalid payload version
        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 99, // Invalid version
            requester: address(0)
        });

        bytes memory invalidResponse = abi.encode(resultConfig, bytes(""));

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidMessageVersion.selector));

        vm.prank(address(clfRouter));
        conceroValidator.handleOracleFulfillment(clfRequestId, invalidResponse, "");
    }

    function test_requestMessageReport_AfterFailedRequest() public {
        uint256 depositAmount = conceroValidator.getMinimumDeposit() * 2;
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        // First request
        vm.prank(relayer);
        bytes32 clfRequestId = conceroValidator.requestMessageReport(
            messageId,
            SRC_CHAIN_SELECTOR,
            srcChainData
        );

        // Simulate CLF error
        vm.prank(address(clfRouter));
        conceroValidator.handleOracleFulfillment(clfRequestId, "", "CLF error");

        // Verify status is Failed
        assertEq(
            uint256(conceroValidator.getClfRequestIdStatus(clfRequestId)),
            uint256(ValidatorTypes.CLFRequestStatus.Failed)
        );

        // Should be able to retry the same messageId after failure with different data
        bytes memory newSrcChainData = abi.encode(uint256(123)); // Different data to get different requestId

        vm.prank(relayer);
        bytes32 newClfRequestId = conceroValidator.requestMessageReport(
            messageId,
            SRC_CHAIN_SELECTOR,
            newSrcChainData
        );

        // Different parameters should produce different requestId
        assertTrue(newClfRequestId != clfRequestId);
        assertEq(
            uint256(conceroValidator.getClfRequestIdStatus(newClfRequestId)),
            uint256(ValidatorTypes.CLFRequestStatus.Pending)
        );
    }
}
