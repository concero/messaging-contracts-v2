// SPDX-License-Identifier: UNLICENSED
/* solhint-disable func-name-mixedcase */
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Errors} from "contracts/ConceroValidator/libraries/Errors.sol";
import {IConceroPriceFeed} from "contracts/interfaces/IConceroPriceFeed.sol";
import {ConceroValidatorTest} from "./base/ConceroValidatorTest.sol";

contract RequestMessageReportTest is ConceroValidatorTest {
    function setUp() public virtual override {
        super.setUp();
        _setPriceFeeds();
    }

    function test_requestMessageReport() public returns (bytes32) {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.prank(s_relayer);
        bytes32 clfRequestId = s_conceroValidator.requestMessageReport(
            messageId,
            SRC_CHAIN_SELECTOR,
            srcChainData
        );

        assertTrue(clfRequestId != bytes32(0));

        // Deposit should be consumed
        assertEq(s_conceroValidator.getDeposit(s_relayer), 0);
        assertEq(address(s_conceroValidator).balance, depositAmount);

        return clfRequestId;
    }

    function test_requestMessageReport_RevertsIfInsufficientDeposit() public {
        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        uint256 depositAmount = s_conceroValidator.getCLFCost();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientDeposit.selector, 0, depositAmount)
        );

        vm.prank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);
    }

    function test_requestMessageReport_RevertsIfNativeUsdRateIsZero() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.startPrank(s_feedUpdater);
        s_conceroPriceFeed.setNativeUsdRate(0);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IConceroPriceFeed.RequiredVariableUnset.selector,
                IConceroPriceFeed.RequiredVariableUnsetType.NativeUSDRate
            )
        );

        vm.prank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);
    }

    function test_requestMessageReport_RevertsIfLastGasPriceIsZero() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.startPrank(s_feedUpdater);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = SRC_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = 0;

        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IConceroPriceFeed.RequiredVariableUnset.selector,
                IConceroPriceFeed.RequiredVariableUnsetType.LastGasPrice
            )
        );

        vm.prank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);
    }

    function test_requestMessageReport_RevertsIfOverEstimatedGasCostIsZero() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        s_conceroValidator.setGasFeeConfig(
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            CLF_GAS_PRICE_OVER_ESTIMATION_BPS,
            0, // clfCallbackGasOverhead = 0
            0 // clfCallbackGasLimit = 0
        );
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAmount.selector));

        vm.prank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);
    }

    function test_requestMessageReport_RevertsIfMessageAlreadyProcessed() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit() * 2;
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.startPrank(s_relayer);

        // First request should succeed
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);

        // Second request with same messageId should revert
        vm.expectRevert(abi.encodeWithSelector(Errors.MessageAlreadyProcessed.selector));

        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);

        vm.stopPrank();
    }
}
