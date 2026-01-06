// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-name-mixedcase
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RelayerLibTest} from "./base/RelayerLibTest.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {IConceroPriceFeed} from "contracts/interfaces/IConceroPriceFeed.sol";

contract RelayerLibTests is RelayerLibTest {
    uint32 internal constant GAS_LIMIT = 300_000;

    function setUp() public override {
        super.setUp();
        _setPriceFeeds();

        // Set native-native rate for destination chain
        vm.startPrank(s_feedUpdater);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = DST_CHAIN_SELECTOR;
        uint256[] memory rates = new uint256[](1);
        rates[0] = 1e18; // 1:1 rate
        s_conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = LAST_GAS_PRICE;
        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        vm.stopPrank();
    }

    /* getFee */

    function test_getFee_ReturnsCorrectAmount() public view {
        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            GAS_LIMIT
        );

        uint256 fee = s_relayerLib.getFee(messageRequest, s_internalValidatorConfigs);

        uint256 dstGasPrice = LAST_GAS_PRICE;
        uint256 dstNativeRate = 1e18; // 1:1 rate
        uint256 expectedFee = (dstGasPrice *
            uint256(SUBMIT_MSG_GAS_OVERHEAD + GAS_LIMIT + VALIDATION_GAS_LIMIT) *
            dstNativeRate) / 1e18;

        assertEq(fee, expectedFee, "Fee should match expected amount");
        assertTrue(fee > 0, "Fee should be greater than 0");
    }

    function test_getFee_RevertsIfFeeTokenIsNotSupported() public {
        address unsupportedFeeToken = makeAddr("UnsupportedFeeToken");
        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            GAS_LIMIT
        );
        messageRequest.feeToken = unsupportedFeeToken;

        vm.expectRevert(
            abi.encodeWithSelector(CommonErrors.FeeTokenNotSupported.selector, unsupportedFeeToken)
        );

        s_relayerLib.getFee(messageRequest, s_internalValidatorConfigs);
    }

    function test_getFee_RevertsIfDstGasPriceIsZero() public {
        vm.startPrank(s_feedUpdater);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = DST_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = 0;
        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        vm.stopPrank();

        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            GAS_LIMIT
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IConceroPriceFeed.RequiredVariableUnset.selector,
                IConceroPriceFeed.RequiredVariableUnsetType.DstGasPrice
            )
        );

        s_relayerLib.getFee(messageRequest, s_internalValidatorConfigs);
    }

    function test_getFee_RevertsIfDstNativeRateIsZero() public {
        vm.startPrank(s_feedUpdater);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = DST_CHAIN_SELECTOR;
        uint256[] memory rates = new uint256[](1);
        rates[0] = 0;
        s_conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);
        vm.stopPrank();

        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            GAS_LIMIT
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IConceroPriceFeed.RequiredVariableUnset.selector,
                IConceroPriceFeed.RequiredVariableUnsetType.DstNativeRate
            )
        );

        s_relayerLib.getFee(messageRequest, s_internalValidatorConfigs);
    }

    /* validate */

    function test_validate_Success() public {
        address[] memory relayers = new address[](1);
        relayers[0] = s_relayer;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        s_relayerLib.setRelayers(relayers, isAllowed);

        s_relayerLib.validate(new bytes(0), s_relayer);
    }

    function test_validate_RevertsIfUnauthorizedRelayerLib() public {
        vm.expectRevert(abi.encodeWithSelector(IRelayerLib.InvalidRelayer.selector, s_relayer));
        s_relayerLib.validate(new bytes(0), s_relayer);
    }

    /* isAllowedRelayer */

    function test_isAllowedRelayer_ReturnsTrue() public {
        address[] memory relayers = new address[](1);
        relayers[0] = s_relayer;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        s_relayerLib.setRelayers(relayers, isAllowed);

        bool result = s_relayerLib.isAllowedRelayer(s_relayer);
        assertTrue(result, "Should return true for allowed relayer");
    }

    function test_isAllowedRelayer_ReturnsFalse() public view {
        bool result = s_relayerLib.isAllowedRelayer(s_relayer);
        assertFalse(result, "Should return false for not allowed relayer");
    }

    /* setRelayers */

    function test_setRelayers_Success() public {
        address[] memory relayers = new address[](2);
        relayers[0] = s_relayer;
        relayers[1] = s_operator;
        bool[] memory isAllowed = new bool[](2);
        isAllowed[0] = true;
        isAllowed[1] = true;

        s_relayerLib.setRelayers(relayers, isAllowed);

        assertTrue(s_relayerLib.isAllowedRelayer(s_relayer), "Relayer should be allowed");
        assertTrue(s_relayerLib.isAllowedRelayer(s_operator), "Operator should be allowed");
    }

    function test_setRelayers_RevertsIfNotOwner() public {
        address[] memory relayers = new address[](1);
        relayers[0] = s_relayer;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        vm.prank(s_user);
        vm.expectRevert(
            "AccessControl: account 0x6ca6d1e2d5347bfab1d91e883f1915560e09129d is missing role 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42"
        );

        s_relayerLib.setRelayers(relayers, isAllowed);
    }

    function test_setRelayers_RevertsIfLengthMismatch() public {
        address[] memory relayers = new address[](2);
        relayers[0] = s_relayer;
        relayers[1] = s_operator;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.LengthMismatch.selector,
                relayers.length,
                isAllowed.length
            )
        );

        s_relayerLib.setRelayers(relayers, isAllowed);
    }

    /* setSubmitMsgGasOverhead */

    function test_setSubmitMsgGasOverhead_Success() public {
        uint32 newOverhead = 200_000;

        s_relayerLib.setSubmitMsgGasOverhead(newOverhead);

        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            GAS_LIMIT
        );

        uint256 fee = s_relayerLib.getFee(messageRequest, s_internalValidatorConfigs);
        uint256 dstGasPrice = LAST_GAS_PRICE;
        uint256 dstNativeRate = 1e18;
        uint256 expectedFee = (dstGasPrice *
            uint256(newOverhead + GAS_LIMIT + VALIDATION_GAS_LIMIT) *
            dstNativeRate) / 1e18;

        assertEq(fee, expectedFee, "Fee should reflect new gas overhead");
    }

    function test_setSubmitMsgGasOverhead_RevertsIfNotOwner() public {
        uint32 newOverhead = 200_000;

        vm.prank(s_user);
        vm.expectRevert(
            "AccessControl: account 0x6ca6d1e2d5347bfab1d91e883f1915560e09129d is missing role 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42"
        );

        s_relayerLib.setSubmitMsgGasOverhead(newOverhead);
    }

    function test_setSubmitMsgGasOverhead_RevertsIfZero() public {
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAmount.selector));

        s_relayerLib.setSubmitMsgGasOverhead(0);
    }

    /* withdrawRelayerFee */

    function test_withdrawRelayerFee_Native_Success() public {
        mockConceroRouterWithFee.setRelayerFee(address(s_relayerLib), 1 ether, address(0));
        deal(address(mockConceroRouterWithFee), 1 ether);

        uint256 balanceBefore = address(this).balance;

        s_relayerLib.withdrawRelayerFee(new address[](1));

        uint256 balanceAfter = address(this).balance;
        assertEq(balanceAfter, balanceBefore + 1 ether, "Balance should be increased by 1 ether");
    }

    function test_withdrawRelayerFee_USDC_Success() public {
        mockConceroRouterWithFee.setRelayerFee(address(s_relayerLib), 1 ether, address(s_usdc));
        deal(s_usdc, address(mockConceroRouterWithFee), 1 ether);

        uint256 balanceBefore = IERC20(s_usdc).balanceOf(address(this));

        address[] memory tokens = new address[](1);
        tokens[0] = address(s_usdc);
        s_relayerLib.withdrawRelayerFee(tokens);

        uint256 balanceAfter = IERC20(s_usdc).balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore + 1 ether, "Balance should be increased by 1 ether");
    }

    /* isFeeTokenSupported */

    function test_isFeeTokenSupported() public {
        assertTrue(s_relayerLib.isFeeTokenSupported(address(0)));
        assertFalse(s_relayerLib.isFeeTokenSupported(makeAddr("UnsupportedFeeToken")));
    }
}
