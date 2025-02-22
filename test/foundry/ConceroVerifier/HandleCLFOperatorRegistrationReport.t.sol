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

import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";
import {OperatorRegistrationReport} from "../scripts/MockCLFReport/OperatorRegistrationReport.sol";
import {RequestOperatorRegistration} from "./RequestOperatorRegistration.t.sol";

contract HandleCLFOperatorRegistrationReport is RequestOperatorRegistration {
    function setUp() public override {
        super.setUp();

        _setPriceFeeds();
        _setOperatorFeesEarned();
        _setOperatorDeposits();
        _setOperatorIsRegistered();
    }

    function test_handleOracleFulfillment_operatorRegistration() public {
        bytes32 clfRequestId = test_requestOperatorRegistration();

        uint256 reportConfig = (uint256(uint8(CommonTypes.CLFReportType.OperatorRegistration)) <<
            248) |
            (uint256(1) << 240) |
            (uint256(uint160(operator)));

        VerifierTypes.OperatorRegistrationResult memory result;
        result.reportConfig = reportConfig;
        result.operatorChains = new CommonTypes.ChainType[](1);
        result.operatorAddresses = new bytes[](1);
        result.operatorActions = new VerifierTypes.OperatorRegistrationAction[](1);

        result.operatorChains[0] = CommonTypes.ChainType.EVM;
        result.operatorAddresses[0] = abi.encodePacked(operator);
        result.operatorActions[0] = VerifierTypes.OperatorRegistrationAction.Register;

        bytes memory response = abi.encode(result);

        OperatorRegistrationReport mockClf = new OperatorRegistrationReport();
        RouterTypes.ClfDonReportSubmission memory clfSubmission = mockClf.getReport();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "");

        // assertTrue(conceroVerifier.isOperatorAllowed(operator));
    }

    function test_handleOracleFulfillment_operatorDeregistration() public {
        bytes32 clfRequestId = test_requestOperatorRegistration();

        uint256 reportConfig = (uint256(uint8(CommonTypes.CLFReportType.OperatorRegistration)) <<
            248) |
            (uint256(1) << 240) |
            (uint256(uint160(operator)));

        VerifierTypes.OperatorRegistrationResult memory result;
        result.reportConfig = reportConfig;
        result.operatorChains = new CommonTypes.ChainType[](1);
        result.operatorAddresses = new bytes[](1);
        result.operatorActions = new VerifierTypes.OperatorRegistrationAction[](1);

        result.operatorChains[0] = CommonTypes.ChainType.EVM;
        result.operatorAddresses[0] = abi.encodePacked(operator);
        result.operatorActions[0] = VerifierTypes.OperatorRegistrationAction.Deregister;

        bytes memory response = abi.encode(result);

        OperatorRegistrationReport operatorRegistrationReport = new OperatorRegistrationReport();
        RouterTypes.ClfDonReportSubmission memory clfSubmission = operatorRegistrationReport
            .getReport();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "");

        // assertFalse(conceroVerifier.isOperatorAllowed(operator));
    }

    function test_handleOracleFulfillment_WithError_operatorRegistration() public {
        bytes32 clfRequestId = test_requestOperatorRegistration();

        OperatorRegistrationReport operatorRegistrationReport = new OperatorRegistrationReport();
        RouterTypes.ClfDonReportSubmission memory clfSubmission = operatorRegistrationReport
            .getReport();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfSubmission.report, "error");

        // assertFalse(conceroVerifier.isPendingCLFRequest(clfRequestId));
        // assertFalse(conceroVerifier.isOperatorAllowed(operator));
    }
}
