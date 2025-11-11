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
import {CommonTypes} from "contracts/common/CommonTypes.sol";

import {Types as ValidatorTypes} from "contracts/ConceroValidator/libraries/Types.sol";
import {Types as RouterTypes} from "../../../contracts/ValidatorLib/libraries/Types.sol";

import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";
import {RequestMessageReportTest} from "./RequestMessageReport.t.sol";
import {DeployConceroValidator} from "../scripts/deploy/DeployConceroValidator.s.sol";
import {IMockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";
import {CLF} from "contracts/ConceroValidator/modules/CLF.sol";

contract HandleCLFMessageReportTest is RequestMessageReportTest {
    DeployConceroValidator deployConceroValidator;

    function setUp() public override {
        super.setUp();

        deployConceroValidator = new DeployConceroValidator();
    }

    function test_handleOracleFulfillment_EmitsRequestFulfilled() public {
        bytes32 clfRequestId = test_requestMessageReport();

        MessageReport messageReport = new MessageReport(
            address(s_conceroValidator),
            deployConceroValidator.s_conceroValidatorSubscriptionId(),
            s_operator,
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            s_user
        );
        bytes memory clfResponse = messageReport.getResponse();

        vm.expectEmit(true, false, false, false);
        emit FunctionsClient.RequestFulfilled(clfRequestId);

        vm.prank(address(s_clfRouter));
        s_conceroValidator.handleOracleFulfillment(clfRequestId, clfResponse, "");
    }

    function test_clfRouter_transmit_messageReport() public {
        // First, request a message report to set up the necessary state
        bytes32 clfRequestId = test_requestMessageReport();

        // Create a message report
        MessageReport messageReport = new MessageReport(
            address(s_conceroValidator),
            deployConceroValidator.s_conceroValidatorSubscriptionId(),
            s_operator,
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            s_user
        );
        RouterTypes.ClfDonReportSubmission memory clfSubmission = messageReport.getReport(
            clfRequestId
        );

        IMockCLFRouter(s_clfRouter).transmit(
            clfSubmission.context,
            clfSubmission.report,
            clfSubmission.rs,
            clfSubmission.ss,
            clfSubmission.rawVs
        );

        assertTrue(
            s_conceroValidator.getClfRequestIdStatus(clfRequestId) ==
                ValidatorTypes.CLFRequestStatus.Fulfilled
        );
    }

    function test_handleOracleFulfillment_WithError() public {
        bytes32 clfRequestId = test_requestMessageReport();

        bytes memory errorMessage = "CLF execution failed";

        vm.expectEmit(false, false, false, true);
        emit CLF.CLFRequestError(errorMessage);

        vm.prank(address(s_clfRouter));
        s_conceroValidator.handleOracleFulfillment(clfRequestId, "", errorMessage);

        // Request status should be Failed
        assertEq(
            uint256(s_conceroValidator.getClfRequestIdStatus(clfRequestId)),
            uint256(ValidatorTypes.CLFRequestStatus.Failed)
        );
    }

    function test_handleOracleFulfillment_InvalidClfRequestId() public {
        bytes32 invalidClfRequestId = bytes32(uint256(999));
        bytes memory response = "";

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidClfRequestId.selector, invalidClfRequestId)
        );

        vm.prank(address(s_clfRouter));
        s_conceroValidator.handleOracleFulfillment(invalidClfRequestId, response, "");
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

        vm.prank(address(s_clfRouter));
        s_conceroValidator.handleOracleFulfillment(clfRequestId, invalidResponse, "");
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

        vm.prank(address(s_clfRouter));
        s_conceroValidator.handleOracleFulfillment(clfRequestId, invalidResponse, "");
    }

    function test_requestMessageReport_AfterFailedRequest() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit() * 2;
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        // First request
        vm.prank(s_relayer);
        bytes32 clfRequestId = s_conceroValidator.requestMessageReport(
            messageId,
            SRC_CHAIN_SELECTOR,
            srcChainData
        );

        // Simulate CLF error
        vm.prank(address(s_clfRouter));
        s_conceroValidator.handleOracleFulfillment(clfRequestId, "", "CLF error");

        // Verify status is Failed
        assertEq(
            uint256(s_conceroValidator.getClfRequestIdStatus(clfRequestId)),
            uint256(ValidatorTypes.CLFRequestStatus.Failed)
        );

        // Should be able to retry the same messageId after failure with different data
        bytes memory newSrcChainData = abi.encode(uint256(123)); // Different data to get different requestId

        vm.prank(s_relayer);
        bytes32 newClfRequestId = s_conceroValidator.requestMessageReport(
            messageId,
            SRC_CHAIN_SELECTOR,
            newSrcChainData
        );

        // Different parameters should produce different requestId
        assertTrue(newClfRequestId != clfRequestId);
        assertEq(
            uint256(s_conceroValidator.getClfRequestIdStatus(newClfRequestId)),
            uint256(ValidatorTypes.CLFRequestStatus.Pending)
        );
    }
}
