// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "../ConceroRouter/base/ConceroRouterTest.sol";

import {CommonConstants} from "contracts/common/CommonConstants.sol";
import {ConceroTypes} from "contracts/ConceroClient/ConceroTypes.sol";
import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {Storage as rs} from "contracts/ConceroRouter/libraries/Storage.sol";

contract GetMessageFeeTest is ConceroRouterTest {
    uint24 public constant CHAIN_SELECTOR_A = 1;
    uint24 public constant CHAIN_SELECTOR_B = 2;

    uint32 public constant GAS_LIMIT = 50_000;

    uint256 public constant BASE_NATIVE_NATIVE_RATE = 1e18;

    uint256 public constant GAS_PRICE_A = 50 gwei;
    uint256 public constant GAS_PRICE_B = 75 gwei;

    function setUp() public override {
        super.setUp();

        uint24[] memory chainSelectors = new uint24[](2);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;

        bool[] memory isSupported = new bool[](2);
        isSupported[0] = true;
        isSupported[1] = true;

        vm.prank(deployer);
        conceroRouter.setSupportedChains(chainSelectors, isSupported);

        vm.prank(feedUpdater);
        conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);
    }

    function test_setGasFeeConfig() public {
        vm.prank(deployer);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_A,
            SUBMIT_MSG_GAS_OVERHEAD,
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_OVERHEAD
        );

        rs.GasFeeConfig memory gasFeeConfig = conceroRouter.getGasFeeConfig();

        assertEq(gasFeeConfig.baseChainSelector, CHAIN_SELECTOR_A, "Incorrect base chain selector");
        assertEq(
            gasFeeConfig.submitMsgGasOverhead,
            SUBMIT_MSG_GAS_OVERHEAD,
            "Incorrect gas overhead"
        );
        assertEq(
            gasFeeConfig.clfCallbackGasOverhead,
            CLF_CALLBACK_GAS_OVERHEAD,
            "Incorrect CLF callback gas overhead"
        );
        assertEq(
            gasFeeConfig.vrfMsgReportRequestGasOverhead,
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            "Incorrect VRF message report request gas overhead"
        );
    }

    function test_getMessageFee_ReturnsBaseFeeNative() public view {
        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: 0})
        );

        uint256 baseFeeNative = _calculateBaseFeeNative();

        assertEq(messageFee, baseFeeNative, "Incorrect base fee native");
    }

    function test_getMessageFee_ReturnsGasFeeNative() public {
        vm.startPrank(deployer);
        conceroRouter.setGasFeeConfig(CHAIN_SELECTOR_A, SUBMIT_MSG_GAS_OVERHEAD, 0, 0);
        vm.stopPrank();

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        uint256 baseFeeNative = _calculateBaseFeeNative();

        assertEq(
            messageFee,
            baseFeeNative +
                _calculateGasFees(
                    GAS_PRICE_A,
                    GAS_LIMIT + SUBMIT_MSG_GAS_OVERHEAD,
                    BASE_NATIVE_NATIVE_RATE
                ),
            "Incorrect gas fee native"
        );
    }

    function test_getMessageFee_ReturnsServiceGasFeeNative() public {
        vm.startPrank(deployer);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_A,
            0,
            CLF_CALLBACK_GAS_OVERHEAD,
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD
        );
        vm.stopPrank();

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: 0})
        );

        uint256 baseFeeNative = _calculateBaseFeeNative();

        assertEq(
            messageFee,
            baseFeeNative +
                _calculateGasFees(
                    GAS_PRICE_A,
                    CLF_CALLBACK_GAS_OVERHEAD + VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
                    BASE_NATIVE_NATIVE_RATE
                ),
            "Incorrect service gas fee native"
        );
    }

    function test_getMessageFee_ReturnsTotalFeeNative() public {
        vm.startPrank(deployer);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_A,
            SUBMIT_MSG_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_OVERHEAD,
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD
        );
        vm.stopPrank();

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        uint256 baseFeeNative = _calculateBaseFeeNative();

        assertEq(
            messageFee,
            baseFeeNative +
                _calculateGasFees(
                    GAS_PRICE_A,
                    GAS_LIMIT + SUBMIT_MSG_GAS_OVERHEAD,
                    BASE_NATIVE_NATIVE_RATE
                ) +
                _calculateGasFees(
                    GAS_PRICE_A,
                    CLF_CALLBACK_GAS_OVERHEAD + VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
                    BASE_NATIVE_NATIVE_RATE
                ),
            "Incorrect total fee native"
        );
    }

    function test_getMessageFee_DifferentBaseChainAndDestChainNativeRate() public {
        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 baseChainNativeRate = BASE_NATIVE_NATIVE_RATE;
        uint256 destChainNativeRate = BASE_NATIVE_NATIVE_RATE / 2; // 0.5 ETH

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, destChainNativeRate);
        _setupPriceFeeds(CHAIN_SELECTOR_B, GAS_PRICE_B, baseChainNativeRate);

        vm.prank(deployer);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_B,
            SUBMIT_MSG_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_OVERHEAD,
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD
        );

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        uint256 baseFeeNative = _calculateBaseFeeNative();

        assertEq(
            messageFee,
            baseFeeNative +
                _calculateGasFees(
                    GAS_PRICE_A,
                    GAS_LIMIT + SUBMIT_MSG_GAS_OVERHEAD,
                    destChainNativeRate
                ) +
                _calculateGasFees(
                    GAS_PRICE_B,
                    CLF_CALLBACK_GAS_OVERHEAD + VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
                    baseChainNativeRate
                ),
            "Incorrect message fee"
        );
    }

    function _calculateBaseFeeNative() internal pure returns (uint256) {
        uint16 totalBps = CommonConstants.CONCERO_MESSAGE_BASE_FEE_BPS_USD +
            CommonConstants.OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD +
            CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD +
            CommonConstants.CLF_PREMIUM_FEE_BPS_USD;

        return CommonUtils.convertUsdBpsToNative(totalBps, NATIVE_USD_RATE);
    }

    function _setupPriceFeeds(
        uint24 chainSelector,
        uint256 gasPrice,
        uint256 nativeNativeRate
    ) internal {
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = chainSelector;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = gasPrice;

        uint256[] memory nativeNativeRates = new uint256[](1);
        nativeNativeRates[0] = nativeNativeRate;

        vm.startPrank(feedUpdater);
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        conceroPriceFeed.setNativeNativeRates(chainSelectors, nativeNativeRates);
        vm.stopPrank();
    }

    function _calculateGasFees(
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 exchangeRate
    ) private pure returns (uint256) {
        return (gasPrice * gasLimit * exchangeRate) / CommonConstants.DECIMALS;
    }
}
