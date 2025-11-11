// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroTest} from "../utils/ConceroTest.sol";

contract GetMessageFeeDataTest is ConceroTest {
    uint24 public constant BASE_CHAIN_SELECTOR = 2;
    uint24 public constant NONEXISTENT_CHAIN = 999;

    uint256 public constant DST_NATIVE_RATE = 1e18;
    uint256 public constant BASE_NATIVE_RATE = 5e17;
    uint256 public constant DST_GAS_PRICE = 50 gwei;
    uint256 public constant BASE_GAS_PRICE = 75 gwei;

    function setUp() public {
        vm.startPrank(s_feedUpdater);
        s_conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);

        // Set native-native rates
        uint24[] memory chainSelectors = new uint24[](2);
        chainSelectors[0] = DST_CHAIN_SELECTOR;
        chainSelectors[1] = BASE_CHAIN_SELECTOR;

        uint256[] memory nativeRates = new uint256[](2);
        nativeRates[0] = DST_NATIVE_RATE;
        nativeRates[1] = BASE_NATIVE_RATE;

        s_conceroPriceFeed.setNativeNativeRates(chainSelectors, nativeRates);

        // Set gas prices
        uint256[] memory gasPrices = new uint256[](2);
        gasPrices[0] = DST_GAS_PRICE;
        gasPrices[1] = BASE_GAS_PRICE;

        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        vm.stopPrank();
    }

    function test_getMessageFeeData_ReturnsCorrectData() public view {
        (
            uint256 nativeUsdRate,
            uint256 dstGasPrice,
            uint256 dstNativeRate,
            uint256 baseGasPrice,
            uint256 baseNativeRate
        ) = s_conceroPriceFeed.getMessageFeeData(DST_CHAIN_SELECTOR, BASE_CHAIN_SELECTOR);

        assertEq(nativeUsdRate, NATIVE_USD_RATE, "Native USD rate should match");
        assertEq(dstGasPrice, DST_GAS_PRICE, "Destination gas price should match");
        assertEq(dstNativeRate, DST_NATIVE_RATE, "Destination native rate should match");
        assertEq(baseGasPrice, BASE_GAS_PRICE, "Base gas price should match");
        assertEq(baseNativeRate, BASE_NATIVE_RATE, "Base native rate should match");
    }

    function test_getMessageFeeData_AfterUpdates() public {
        uint256 newNativeUsdRate = 2500 * 1e18;
        uint256 newDstGasPrice = 100 gwei;
        uint256 newBaseNativeRate = 15 * 1e17;

        vm.startPrank(s_feedUpdater);

        // Update some values
        s_conceroPriceFeed.setNativeUsdRate(newNativeUsdRate);

        uint24[] memory chainSelectors = new uint24[](2);
        chainSelectors[0] = DST_CHAIN_SELECTOR;
        chainSelectors[1] = BASE_CHAIN_SELECTOR;

        uint256[] memory gasPrices = new uint256[](2);
        gasPrices[0] = newDstGasPrice;
        gasPrices[1] = BASE_GAS_PRICE; // Keep base gas price unchanged
        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        uint256[] memory nativeRates = new uint256[](2);
        nativeRates[0] = DST_NATIVE_RATE; // Keep dst native rate unchanged
        nativeRates[1] = newBaseNativeRate;
        s_conceroPriceFeed.setNativeNativeRates(chainSelectors, nativeRates);

        vm.stopPrank();

        (
            uint256 nativeUsdRate,
            uint256 dstGasPrice,
            uint256 dstNativeRate,
            uint256 baseGasPrice,
            uint256 baseNativeRate
        ) = s_conceroPriceFeed.getMessageFeeData(DST_CHAIN_SELECTOR, BASE_CHAIN_SELECTOR);

        assertEq(nativeUsdRate, newNativeUsdRate, "Native USD rate should be updated");
        assertEq(dstGasPrice, newDstGasPrice, "Destination gas price should be updated");
        assertEq(dstNativeRate, DST_NATIVE_RATE, "Destination native rate should remain unchanged");
        assertEq(baseGasPrice, BASE_GAS_PRICE, "Base gas price should remain unchanged");
        assertEq(baseNativeRate, newBaseNativeRate, "Base native rate should be updated");
    }
}
