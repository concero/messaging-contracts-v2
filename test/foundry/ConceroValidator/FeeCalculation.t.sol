// SPDX-License-Identifier: UNLICENSED
/* solhint-disable func-name-mixedcase */
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {CommonConstants} from "contracts/common/CommonConstants.sol";

import {ConceroValidatorTest} from "./base/ConceroValidatorTest.sol";

contract FeeCalculationTest is ConceroValidatorTest {
    function setUp() public override {
        super.setUp();
    }

    function test_ChargeFeeCorrectly() public returns (bytes32) {
        assertEq(address(conceroValidator).balance, 0);

        uint256 minimumDeposit = conceroValidator.getCLFCost();
        _deposit(minimumDeposit);

        assertEq(conceroValidator.getDeposit(relayer), minimumDeposit);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.prank(relayer);
        bytes32 clfRequestId = conceroValidator.requestMessageReport(
            messageId,
            SRC_CHAIN_SELECTOR,
            srcChainData
        );

        // Deposit should be consumed as fee
        assertEq(conceroValidator.getDeposit(relayer), 0);
        assertEq(address(conceroValidator).balance, minimumDeposit);

        return clfRequestId;
    }

    function test_getCLFCost() public {
        uint256 clfCost = conceroValidator.getCLFCost();

        // Verify CLF cost is greater than zero
        assertTrue(clfCost > 0);

        // Verify CLF cost calculation
        (uint256 nativeUsdRate, uint256 lastGasPrice) = conceroPriceFeed
            .getNativeUsdRateAndGasPrice();

        uint256 gasCost = (CLF_CALLBACK_GAS_OVERHEAD + CLF_CALLBACK_GAS_LIMIT) * lastGasPrice;
        uint256 overEstimatedGasCost = gasCost +
            ((gasCost * CLF_GAS_PRICE_OVER_ESTIMATION_BPS) / CommonConstants.BPS_DENOMINATOR);

        uint256 premiumFee = CommonUtils.convertUsdBpsToNative(
            CommonConstants.CLF_PREMIUM_FEE_BPS_USD,
            nativeUsdRate
        );

        uint256 expectedClfCost = overEstimatedGasCost + premiumFee;

        assertEq(clfCost, expectedClfCost);
    }

    function test_multipleFeeCharges() public {
        uint256 clfCost = conceroValidator.getCLFCost();
        uint256 totalDeposit = clfCost * 10;

        _deposit(totalDeposit);

        bytes32 messageId1 = bytes32(uint256(1));
        bytes32 messageId2 = bytes32(uint256(2));
        bytes32 messageId3 = bytes32(uint256(3));
        bytes memory srcChainData = new bytes(0);

        vm.startPrank(relayer);

        // First request
        conceroValidator.requestMessageReport(messageId1, SRC_CHAIN_SELECTOR, srcChainData);
        assertEq(conceroValidator.getDeposit(relayer), totalDeposit - clfCost);

        // Second request
        conceroValidator.requestMessageReport(messageId2, SRC_CHAIN_SELECTOR, srcChainData);
        assertEq(conceroValidator.getDeposit(relayer), totalDeposit - (clfCost * 2));

        // Third request
        conceroValidator.requestMessageReport(messageId3, SRC_CHAIN_SELECTOR, srcChainData);
        assertEq(conceroValidator.getDeposit(relayer), totalDeposit - (clfCost * 3));

        vm.stopPrank();

        assertEq(address(conceroValidator).balance, totalDeposit);
    }
}
