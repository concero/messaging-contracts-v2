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

contract SetNativeNativeRatesTest is ConceroPriceFeedTest {
    uint24 public constant CHAIN_SELECTOR_A = 1;
    uint24 public constant CHAIN_SELECTOR_B = 2;
    uint24 public constant CHAIN_SELECTOR_C = 3;

    uint256 public constant RATE_A = 1 * 1e18; // 1:1 rate
    uint256 public constant RATE_B = 5 * 1e17; // 0.5:1 rate
    uint256 public constant RATE_C = 2 * 1e18; // 2:1 rate
    uint256 public constant UPDATED_RATE = 15 * 1e17; // 1.5:1 rate

    function setUp() public override {
        super.setUp();
    }

    function test_setNativeNativeRates_MultipleChains() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](3);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;
        chainSelectors[2] = CHAIN_SELECTOR_C;

        uint256[] memory rates = new uint256[](3);
        rates[0] = RATE_A;
        rates[1] = RATE_B;
        rates[2] = RATE_C;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        // Verify all rates were set correctly
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            RATE_A,
            "Rate A not set correctly"
        );
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_B),
            RATE_B,
            "Rate B not set correctly"
        );
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_C),
            RATE_C,
            "Rate C not set correctly"
        );

        vm.stopPrank();
    }

    function test_setNativeNativeRates_SingleChain() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            RATE_A,
            "Single rate not set correctly"
        );

        vm.stopPrank();
    }

    function test_setNativeNativeRates_UpdateExistingRates() public {
        vm.startPrank(feedUpdater);

        // Set initial rates
        uint24[] memory chainSelectors = new uint24[](2);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;

        uint256[] memory rates = new uint256[](2);
        rates[0] = RATE_A;
        rates[1] = RATE_B;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        // Verify initial values
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            RATE_A,
            "Initial rate A not set"
        );
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_B),
            RATE_B,
            "Initial rate B not set"
        );

        // Update one rate
        uint24[] memory updateChainSelectors = new uint24[](1);
        updateChainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory updateRates = new uint256[](1);
        updateRates[0] = UPDATED_RATE;

        conceroPriceFeed.setNativeNativeRates(updateChainSelectors, updateRates);

        // Verify updated values
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            UPDATED_RATE,
            "Rate A not updated correctly"
        );
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_B),
            RATE_B,
            "Rate B should remain unchanged"
        );

        vm.stopPrank();
    }

    function test_setNativeNativeRates_ZeroRates() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](2);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;

        uint256[] memory rates = new uint256[](2);
        rates[0] = 0;
        rates[1] = 0;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            0,
            "Zero rate A should be allowed"
        );
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_B),
            0,
            "Zero rate B should be allowed"
        );

        vm.stopPrank();
    }

    function test_setNativeNativeRates_WhenArrayLengthsMismatch_Reverts() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](3);
        chainSelectors[0] = CHAIN_SELECTOR_A;
        chainSelectors[1] = CHAIN_SELECTOR_B;
        chainSelectors[2] = CHAIN_SELECTOR_C;

        uint256[] memory rates = new uint256[](2);
        rates[0] = RATE_A;
        rates[1] = RATE_B;

        vm.expectRevert(CommonErrors.LengthMismatch.selector);
        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        vm.stopPrank();
    }

    function test_setNativeNativeRates_WhenNotFeedUpdater_Reverts() public {
        address unauthorizedUser = address(0x1234);

        vm.startPrank(unauthorizedUser);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        vm.expectRevert(CommonErrors.Unauthorized.selector);
        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        vm.stopPrank();
    }

    function test_setNativeNativeRates_OnlyFeedUpdater() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            RATE_A,
            "FeedUpdater should be able to set rates"
        );

        vm.stopPrank();
    }

    function test_setNativeNativeRates_OnlyOwner() public {
        vm.startPrank(deployer); // deployer is the owner

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);
        assertEq(
            conceroPriceFeed.getNativeNativeRate(CHAIN_SELECTOR_A),
            RATE_A,
            "Owner should be able to set rates"
        );

        vm.stopPrank();
    }

    function test_setNativeNativeRates_StorageVerification() public {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = CHAIN_SELECTOR_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        // Verify storage directly
        uint256 storedValue = conceroPriceFeed.getStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.nativeNativeRates,
            bytes32(uint256(CHAIN_SELECTOR_A))
        );

        assertEq(storedValue, RATE_A, "Storage verification failed");

        vm.stopPrank();
    }
}
