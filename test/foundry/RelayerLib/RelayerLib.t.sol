// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-name-mixedcase
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

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

        uint256 fee = relayerLib.getFee(messageRequest);

        uint256 dstGasPrice = LAST_GAS_PRICE;
        uint256 dstNativeRate = 1e18; // 1:1 rate
        uint256 expectedFee = (dstGasPrice *
            uint256(SUBMIT_MSG_GAS_OVERHEAD + GAS_LIMIT) *
            dstNativeRate) / 1e18;

        assertEq(fee, expectedFee, "Fee should match expected amount");
        assertTrue(fee > 0, "Fee should be greater than 0");
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

        relayerLib.getFee(messageRequest);
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

        relayerLib.getFee(messageRequest);
    }

    /* validate */

    function test_validate_Success() public {
        address[] memory relayers = new address[](1);
        relayers[0] = s_relayer;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        relayerLib.setRelayers(relayers, isAllowed);

        relayerLib.validate(new bytes(0), s_relayer);
    }

    function test_validate_RevertsIfRelayerNotAllowed() public {
        vm.expectRevert(abi.encodeWithSelector(IRelayerLib.InvalidRelayer.selector));
        relayerLib.validate(new bytes(0), s_relayer);
    }

    /* getDstLib */

    function test_getDstLib_ReturnsCorrectValue() public {
        address dstLibAddress = address(0x456);
        uint24[] memory dstChainSelectors = new uint24[](1);
        dstChainSelectors[0] = DST_CHAIN_SELECTOR;
        address[] memory dstLibs = new address[](1);
        dstLibs[0] = dstLibAddress;

        relayerLib.setDstLibs(dstChainSelectors, dstLibs);

        bytes memory storedDstLib = relayerLib.getDstLib(DST_CHAIN_SELECTOR);
        address decodedAddress = abi.decode(storedDstLib, (address));

        assertEq(decodedAddress, dstLibAddress, "getDstLib should return correct value");
    }

    /* isAllowedRelayer */

    function test_isAllowedRelayer_ReturnsTrue() public {
        address[] memory relayers = new address[](1);
        relayers[0] = s_relayer;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        relayerLib.setRelayers(relayers, isAllowed);

        bool result = relayerLib.isAllowedRelayer(s_relayer);
        assertTrue(result, "Should return true for allowed relayer");
    }

    function test_isAllowedRelayer_ReturnsFalse() public view {
        bool result = relayerLib.isAllowedRelayer(s_relayer);
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

        relayerLib.setRelayers(relayers, isAllowed);

        assertTrue(relayerLib.isAllowedRelayer(s_relayer), "Relayer should be allowed");
        assertTrue(relayerLib.isAllowedRelayer(s_operator), "Operator should be allowed");
    }

    function test_setRelayers_RevertsIfNotOwner() public {
        address[] memory relayers = new address[](1);
        relayers[0] = s_relayer;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        vm.prank(s_user);
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.Unauthorized.selector));

        relayerLib.setRelayers(relayers, isAllowed);
    }

    function test_setRelayers_RevertsIfLengthMismatch() public {
        address[] memory relayers = new address[](2);
        relayers[0] = s_relayer;
        relayers[1] = s_operator;
        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        vm.expectRevert(abi.encodeWithSelector(CommonErrors.LengthMismatch.selector));

        relayerLib.setRelayers(relayers, isAllowed);
    }

    /* setDstLibs */

    function test_setDstLibs_Success() public {
        address dstLib1 = address(0x123);
        address dstLib2 = address(0x456);
        uint24[] memory dstChainSelectors = new uint24[](2);
        dstChainSelectors[0] = DST_CHAIN_SELECTOR;
        dstChainSelectors[1] = uint24(999);
        address[] memory dstLibs = new address[](2);
        dstLibs[0] = dstLib1;
        dstLibs[1] = dstLib2;

        relayerLib.setDstLibs(dstChainSelectors, dstLibs);

        bytes memory storedDstLib1 = relayerLib.getDstLib(DST_CHAIN_SELECTOR);
        bytes memory storedDstLib2 = relayerLib.getDstLib(uint24(999));

        assertEq(abi.decode(storedDstLib1, (address)), dstLib1, "First dst lib should be set");
        assertEq(abi.decode(storedDstLib2, (address)), dstLib2, "Second dst lib should be set");
    }

    function test_setDstLibs_RevertsIfNotOwner() public {
        uint24[] memory dstChainSelectors = new uint24[](1);
        dstChainSelectors[0] = DST_CHAIN_SELECTOR;
        address[] memory dstLibs = new address[](1);
        dstLibs[0] = address(0x123);

        vm.prank(s_user);
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.Unauthorized.selector));

        relayerLib.setDstLibs(dstChainSelectors, dstLibs);
    }

    function test_setDstLibs_RevertsIfLengthMismatch() public {
        uint24[] memory dstChainSelectors = new uint24[](2);
        dstChainSelectors[0] = DST_CHAIN_SELECTOR;
        dstChainSelectors[1] = uint24(999);
        address[] memory dstLibs = new address[](1);
        dstLibs[0] = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(CommonErrors.LengthMismatch.selector));

        relayerLib.setDstLibs(dstChainSelectors, dstLibs);
    }

    /* setSubmitMsgGasOverhead */

    function test_setSubmitMsgGasOverhead_Success() public {
        uint32 newOverhead = 200_000;

        relayerLib.setSubmitMsgGasOverhead(newOverhead);

        IConceroRouter.MessageRequest memory messageRequest = _createMessageRequest(
            DST_CHAIN_SELECTOR,
            GAS_LIMIT
        );

        uint256 fee = relayerLib.getFee(messageRequest);
        uint256 dstGasPrice = LAST_GAS_PRICE;
        uint256 dstNativeRate = 1e18;
        uint256 expectedFee = (dstGasPrice * uint256(newOverhead + GAS_LIMIT) * dstNativeRate) /
            1e18;

        assertEq(fee, expectedFee, "Fee should reflect new gas overhead");
    }

    function test_setSubmitMsgGasOverhead_RevertsIfNotOwner() public {
        uint32 newOverhead = 200_000;

        vm.prank(s_user);
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.Unauthorized.selector));

        relayerLib.setSubmitMsgGasOverhead(newOverhead);
    }

    function test_setSubmitMsgGasOverhead_RevertsIfZero() public {
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAmount.selector));

        relayerLib.setSubmitMsgGasOverhead(0);
    }
}
