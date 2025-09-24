// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Namespaces} from "contracts/ConceroPriceFeed/libraries/Storage.sol";
import {PriceFeedSlots} from "contracts/ConceroPriceFeed/libraries/StorageSlots.sol";

import {ConceroPriceFeedTest} from "./base/ConceroPriceFeedTest.sol";

contract SetLastGasPricesTest is ConceroPriceFeedTest {
    uint24 public constant CHAIN_SELECTOR_A = 1;
    uint24 public constant CHAIN_SELECTOR_B = 2;
    uint24 public constant CHAIN_SELECTOR_C = 3;
    uint24 public constant UNSUPPORTED_CHAIN_SELECTOR = 999;

    uint256 public constant GAS_PRICE_A = 50 gwei;
    uint256 public constant GAS_PRICE_B = 75 gwei;
    uint256 public constant GAS_PRICE_C = 100 gwei;
    uint256 public constant UPDATED_GAS_PRICE = 150 gwei;

    function setUp() public override {
        super.setUp();
    }

    function test_setLastGasPrices() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](3);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;
        chainSelectors[2] = CHAIN_SELECTOR_C;

        uint256[] memory gasPrices = new uint256[](3);
        gasPrices[0] = GAS_PRICE_A;
        gasPrices[1] = GAS_PRICE_B;
        gasPrices[2] = GAS_PRICE_C;

        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        uint256 storedGasPriceA = conceroPriceFeed.getLastGasPrice(CHAIN_SELECTOR_A);
        uint256 storedGasPriceB = conceroPriceFeed.getLastGasPrice(CHAIN_SELECTOR_B);
        uint256 storedGasPriceC = conceroPriceFeed.getLastGasPrice(CHAIN_SELECTOR_C);

        assertEq(storedGasPriceA, GAS_PRICE_A, "Incorrect gas price for chain selector A");
        assertEq(storedGasPriceB, GAS_PRICE_B, "Incorrect gas price for chain selector B");
        assertEq(storedGasPriceC, GAS_PRICE_C, "Incorrect gas price for chain selector C");

        vm.stopPrank();
    }

    function test_setLastGasPrices_SingleChain() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = GAS_PRICE_A;

        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        uint256 storedGasPrice = conceroPriceFeed.getLastGasPrice(CHAIN_SELECTOR_A);

        assertEq(storedGasPrice, GAS_PRICE_A, "Incorrect gas price for chain selector A");

        vm.stopPrank();
    }

    function test_setLastGasPrices_UpdateExistingValue() public {
        vm.startPrank(feedUpdater);

        // First set initial value
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = GAS_PRICE_A;

        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        // Now update it
        gasPrices[0] = UPDATED_GAS_PRICE;
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        uint256 storedGasPrice = conceroPriceFeed.getLastGasPrice(CHAIN_SELECTOR_A);

        assertEq(storedGasPrice, UPDATED_GAS_PRICE, "Gas price was not correctly updated");

        vm.stopPrank();
    }

    function test_setLastGasPrices_WhenArrayLengthsMismatch_Reverts() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](3);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;
        chainSelectors[2] = CHAIN_SELECTOR_C;

        uint256[] memory gasPrices = new uint256[](2);
        gasPrices[0] = GAS_PRICE_A;
        gasPrices[1] = GAS_PRICE_B;

        vm.expectRevert(CommonErrors.LengthMismatch.selector);
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        vm.stopPrank();
    }

    function test_setLastGasPrices_WhenNotFeedUpdater_Reverts() public {
        vm.startPrank(address(0x1234));

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = GAS_PRICE_A;

        vm.expectRevert(CommonErrors.Unauthorized.selector);
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        vm.stopPrank();
    }

    function test_setLastGasPrices_WithEmptyArrays() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](0);
        uint256[] memory gasPrices = new uint256[](0);

        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        vm.stopPrank();
    }
}
