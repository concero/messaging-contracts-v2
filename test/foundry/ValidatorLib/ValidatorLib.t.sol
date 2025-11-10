// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-name-mixedcase
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "contracts/ValidatorLib/libraries/Types.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {CommonConstants} from "contracts/common/CommonConstants.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IValidatorLib} from "contracts/interfaces/IValidatorLib.sol";
import {ValidatorLibTest} from "./base/ValidatorLibTest.sol";

contract ValidatorLibTests is ValidatorLibTest {
    bytes32 internal constant TEST_MESSAGE_ID = bytes32(uint256(1));
    bytes internal constant TEST_MESSAGE = "Test message";
    uint256 internal constant GAS_LIMIT = 1_000_000;

    function setUp() public override {
        super.setUp();

        _setPriceFeeds();
    }

    /* isValid */

    function test_isValid_ValidMessage() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertTrue(result, "Message should be valid");
    }

    function test_isValid_InvalidSignatures() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        reportSubmission.rs[0] = bytes32(uint256(1));

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with bad signatures");
    }

    function test_isValid_InvalidChainSelector() public view {
        uint24 wrongChainSelector = uint24(999);

        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            wrongChainSelector,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with wrong chain selector");
    }

    function test_isValid_InvalidIndex() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        bytes memory validation = abi.encode(reportSubmission, uint256(999));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with out of bounds index");
    }

    function test_isValid_InvalidClient() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);

        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload),
            bytes32("requestId"),
            address(0x999), // Invalid client
            deployValidatorLib.s_conceroValidatorSubscriptionId()
        );

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with wrong client");
    }

    function test_isValid_InvalidSubscriptionId() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);

        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload),
            bytes32("requestId"),
            address(s_conceroValidator),
            uint64(999) // Invalid subscription ID
        );

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with wrong subscription ID");
    }

    function test_isValid_IncorrectNumberOfSignatures() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        // Remove one signature to make the number of signatures incorrect
        bytes32[] memory newRs = new bytes32[](2);
        newRs[0] = reportSubmission.rs[0];
        newRs[1] = reportSubmission.rs[1];
        reportSubmission.rs = newRs;

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with incorrect number of signatures");
    }

    function test_isValid_DuplicateSignatures() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        // Duplicate the first signature
        reportSubmission.rs[1] = reportSubmission.rs[0];
        reportSubmission.ss[1] = reportSubmission.ss[0];

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with duplicate signatures");
    }

    function test_isValid_UnauthorizedSigner() public view {
        Types.EvmDstChainData memory dstChainData = _createDstChainData(
            address(conceroClient),
            GAS_LIMIT
        );
        CommonTypes.ResultConfig memory resultConfig = _createResultConfig(s_operator);
        bytes[] memory allowedOperators = _createAllowedOperators(s_operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = _createMessagePayload(
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            dstChainData,
            allowedOperators
        );

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        // Create a signature from an unauthorized address (this will result in address(0) when recovered)
        reportSubmission.rs[0] = bytes32(0);
        reportSubmission.ss[0] = bytes32(0);

        bytes memory validation = abi.encode(reportSubmission, uint256(0));

        bool result = validatorLib.isValid(new bytes(0), validation);
        assertFalse(result, "Message should be invalid with unauthorized signer");
    }

    /* getFee */

    function test_getFee_ReturnsCorrectAmount() public view {
        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            Types.EvmDstChainData(address(conceroClient), GAS_LIMIT),
            TEST_MESSAGE
        );

        uint256 fee = validatorLib.getFee(messageRequest);

        uint256 expectedFee = (uint256(VALIDATOR_LIB_FEE_BPS_USD) * 1e18) /
            CommonConstants.BPS_DENOMINATOR;
        expectedFee = (expectedFee * 1e18) / NATIVE_USD_RATE;

        assertEq(fee, expectedFee, "Fee should match expected amount");
        assertTrue(fee > 0, "Fee should be greater than 0");
    }

    function test_getFee_RevertsIfNativeUsdRateIsZero() public {
        vm.startPrank(s_feedUpdater);
        s_conceroPriceFeed.setNativeUsdRate(0);
        vm.stopPrank();

        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            Types.EvmDstChainData(address(conceroClient), GAS_LIMIT),
            TEST_MESSAGE
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.RequiredVariableUnset.selector,
                CommonErrors.RequiredVariableUnsetType.NativeUSDRate
            )
        );

        validatorLib.getFee(messageRequest);
    }

    /* setDstLib */

    function test_setDstLib_Success() public {
        address dstLibAddress = address(0x456);

        validatorLib.setDstLib(SRC_CHAIN_SELECTOR, dstLibAddress);

        bytes memory storedDstLib = validatorLib.getDstLib(SRC_CHAIN_SELECTOR);
        address decodedAddress = abi.decode(storedDstLib, (address));

        assertEq(decodedAddress, dstLibAddress, "Dst lib should be set correctly");
    }

    function test_setDstLib_RevertsIfNotOwner() public {
        address dstLibAddress = address(0x456);

        vm.prank(s_user);
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.Unauthorized.selector));

        validatorLib.setDstLib(SRC_CHAIN_SELECTOR, dstLibAddress);
    }

    function test_setDstLib_RevertsIfSameChain() public {
        address dstLibAddress = address(0x456);

        vm.expectRevert(abi.encodeWithSelector(IValidatorLib.InvalidChainSelector.selector));

        validatorLib.setDstLib(DST_CHAIN_SELECTOR, dstLibAddress);
    }

    function test_getDstLib_ReturnsCorrectValue() public {
        address dstLibAddress = address(0x789);

        validatorLib.setDstLib(SRC_CHAIN_SELECTOR, dstLibAddress);

        bytes memory storedDstLib = validatorLib.getDstLib(SRC_CHAIN_SELECTOR);
        address decodedAddress = abi.decode(storedDstLib, (address));

        assertEq(decodedAddress, dstLibAddress, "getDstLib should return correct value");
    }
}
