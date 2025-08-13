// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {CommonConstants, ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";

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
        _setGasFeeConfig();
        _setOperatorFeesEarned();
        _setOperatorDeposits();
        _setOperatorIsRegistered();
    }
    function test_handleOracleFulfillment_operatorRegistration() public {
        bytes32 clfRequestId = test_requestOperatorRegistration();

        OperatorRegistrationReport report = new OperatorRegistrationReport();
        bytes memory clfResponse = report.getResponse();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfResponse, "");

        assertTrue(conceroVerifier.isOperatorRegistered(operator));
    }

    function test_operatorDepositReturnedAfterRegistration() public {
        uint256 initialDeposit = conceroVerifier.getOperatorDeposit(operator);
        uint256 clfCost = conceroVerifier.getCLFCost();

        // Request operator registration (this will withhold the deposit)
        bytes32 clfRequestId = test_requestOperatorRegistration();

        uint256 depositAfterRequest = conceroVerifier.getOperatorDeposit(operator);
        assertEq(
            depositAfterRequest,
            initialDeposit - clfCost,
            "Deposit should be withheld after registration request"
        );

        // Handle the CLF response (simulate successful registration)
        OperatorRegistrationReport report = new OperatorRegistrationReport();
        bytes memory clfResponse = report.getResponse();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfResponse, "");

        uint256 depositAfterResponse = conceroVerifier.getOperatorDeposit(operator);
        assertEq(
            depositAfterResponse,
            initialDeposit,
            "Deposit should be returned after successful registration"
        );
    }
}
