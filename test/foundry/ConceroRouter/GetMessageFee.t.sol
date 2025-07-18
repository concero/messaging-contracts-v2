// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

import {CommonConstants} from "contracts/common/CommonConstants.sol";
import {ConceroTypes} from "contracts/ConceroClient/ConceroTypes.sol";
import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";

contract GetMessageFeeTest is ConceroRouterTest {
    uint24 public constant CHAIN_SELECTOR_A = 1;
    uint24 public constant CHAIN_SELECTOR_B = 2;

    uint32 public constant GAS_LIMIT = 50_000;
    uint32 public constant GAS_OVERHEAD = 100_000;
    uint32 public constant RELAYER_GAS_LIMIT = 150_000;
    uint32 public constant VERIFIER_GAS_LIMIT = 200_000;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant BASE_FEE_NATIVE = 1e13; // Base fee is 0.00001 ETH
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
        conceroRouter.setNativeUsdRate(NATIVE_USD_RATE);
    }

    function test_setGasFeeConfig() public {
        vm.startPrank(feedUpdater);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_A, GAS_OVERHEAD, RELAYER_GAS_LIMIT, VERIFIER_GAS_LIMIT
        );
        vm.stopPrank();

        uint8 gasFeeConfigSlotNumber = 1;

        // Read the entire slot
        uint256 gasFeeConfigValue =
            conceroRouter.getStorage(Namespaces.PRICEFEED, gasFeeConfigSlotNumber, bytes32(0));

        // Extract fields in the same order as in the structure
        uint24 baseChainSelector = uint24(gasFeeConfigValue); // lower 24 bits
        uint32 gasOverhead = uint32(gasFeeConfigValue >> 24); // next 32 bits
        uint32 relayerGasLimit = uint32(gasFeeConfigValue >> 56); // next 32 bits (24+32)
        uint32 verifierGasLimit = uint32(gasFeeConfigValue >> 88); // next 32 bits (24+32+32)

        assertEq(baseChainSelector, CHAIN_SELECTOR_A, "Incorrect base chain selector");
        assertEq(gasOverhead, GAS_OVERHEAD, "Incorrect gas overhead");
        assertEq(relayerGasLimit, RELAYER_GAS_LIMIT, "Incorrect relayer gas limit");
        assertEq(verifierGasLimit, VERIFIER_GAS_LIMIT, "Incorrect verifier gas limit");
    }

    function test_getMessageFee_ReturnsBaseFeeNative() public view {
        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: 0})
        );

        // 0.01 USD + 0.01 USD = 0.02 USD or 0.00001 ETH (1ETH == 2000 USD)
        uint256 baseFeeNative = CommonUtils.convertUsdBpsToNative(
            CommonConstants.CONCERO_MESSAGE_BASE_FEE_BPS_USD
                + CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            NATIVE_USD_RATE
        );

        assertEq(messageFee, baseFeeNative, "Incorrect base fee native");
    }

    function test_getMessageFee_ReturnsGasFeeNative() public {
        _checkDefaultState();

        vm.startPrank(feedUpdater);
        conceroRouter.setGasFeeConfig(CHAIN_SELECTOR_A, GAS_OVERHEAD, 0, 0);
        vm.stopPrank();

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        assertEq(
            messageFee,
            BASE_FEE_NATIVE
                + _calculateGasFees(GAS_PRICE_A, GAS_LIMIT + GAS_OVERHEAD, BASE_NATIVE_NATIVE_RATE),
            "Incorrect gas fee native"
        );
    }

    function test_getMessageFee_ReturnsServiceGasFeeNative() public {
        _checkDefaultState();

        vm.startPrank(feedUpdater);
        conceroRouter.setGasFeeConfig(CHAIN_SELECTOR_A, 0, RELAYER_GAS_LIMIT, VERIFIER_GAS_LIMIT);
        vm.stopPrank();

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: 0})
        );

        assertEq(
            messageFee,
            BASE_FEE_NATIVE
                + _calculateGasFees(
                    GAS_PRICE_A, RELAYER_GAS_LIMIT + VERIFIER_GAS_LIMIT, BASE_NATIVE_NATIVE_RATE
                ),
            "Incorrect service gas fee native"
        );
    }

    function test_getMessageFee_ReturnsTotalFeeNative() public {
        _checkDefaultState();

        vm.startPrank(feedUpdater);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_A, GAS_OVERHEAD, RELAYER_GAS_LIMIT, VERIFIER_GAS_LIMIT
        );
        vm.stopPrank();

        _setupPriceFeeds(CHAIN_SELECTOR_A, GAS_PRICE_A, BASE_NATIVE_NATIVE_RATE);

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        assertEq(
            messageFee,
            BASE_FEE_NATIVE
                + _calculateGasFees(GAS_PRICE_A, GAS_LIMIT + GAS_OVERHEAD, BASE_NATIVE_NATIVE_RATE)
                + _calculateGasFees(
                    GAS_PRICE_A, RELAYER_GAS_LIMIT + VERIFIER_GAS_LIMIT, BASE_NATIVE_NATIVE_RATE
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

        vm.prank(feedUpdater);
        conceroRouter.setGasFeeConfig(
            CHAIN_SELECTOR_B, GAS_OVERHEAD, RELAYER_GAS_LIMIT, VERIFIER_GAS_LIMIT
        );

        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        assertEq(
            messageFee,
            BASE_FEE_NATIVE
                + _calculateGasFees(GAS_PRICE_A, GAS_LIMIT + GAS_OVERHEAD, destChainNativeRate)
                + _calculateGasFees(
                    GAS_PRICE_B, RELAYER_GAS_LIMIT + VERIFIER_GAS_LIMIT, baseChainNativeRate
                ),
            "Incorrect message fee"
        );
    }

    function _checkDefaultState() internal view {
        uint256 messageFee = conceroRouter.getMessageFee(
            CHAIN_SELECTOR_A,
            false,
            address(0),
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: GAS_LIMIT})
        );

        assertEq(messageFee, BASE_FEE_NATIVE);
    }

    function _setupPriceFeeds(uint24 chainSelector, uint256 gasPrice, uint256 nativeNativeRate)
        internal
    {
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = chainSelector;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = gasPrice;

        uint256[] memory nativeNativeRates = new uint256[](1);
        nativeNativeRates[0] = nativeNativeRate;

        vm.startPrank(feedUpdater);
        conceroRouter.setLastGasPrices(chainSelectors, gasPrices);
        conceroRouter.setNativeNativeRates(chainSelectors, nativeNativeRates);
        vm.stopPrank();
    }

    function _calculateGasFees(uint256 gasPrice, uint256 gasLimit, uint256 exchangeRate)
        private
        pure
        returns (uint256)
    {
        return (gasPrice * gasLimit * exchangeRate) / PRECISION;
    }
}
