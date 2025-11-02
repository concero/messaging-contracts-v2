// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroTest} from "../utils/ConceroTest.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Namespaces} from "contracts/ConceroPriceFeed/libraries/Storage.sol";
import {PriceFeedSlots} from "contracts/ConceroPriceFeed/libraries/StorageSlots.sol";

contract SetNativeUsdRateTest is ConceroTest {
    uint256 public constant INITIAL_RATE = 2000e18; // $2000 per native token
    uint256 public constant UPDATED_RATE = 2500e18; // $2500 per native token
    uint256 public constant ZERO_RATE = 0;

    function test_setNativeUsdRate_Success() public {
        vm.startPrank(s_feedUpdater);

        s_conceroPriceFeed.setNativeUsdRate(INITIAL_RATE);

        uint256 storedRate = s_conceroPriceFeed.getNativeUsdRate();
        assertEq(storedRate, INITIAL_RATE, "Native USD rate was not set correctly");

        vm.stopPrank();
    }

    function test_setNativeUsdRate_UpdateExistingRate() public {
        vm.startPrank(s_feedUpdater);

        // Set initial rate
        s_conceroPriceFeed.setNativeUsdRate(INITIAL_RATE);
        assertEq(s_conceroPriceFeed.getNativeUsdRate(), INITIAL_RATE, "Initial rate not set");

        // Update to new rate
        s_conceroPriceFeed.setNativeUsdRate(UPDATED_RATE);
        assertEq(
            s_conceroPriceFeed.getNativeUsdRate(),
            UPDATED_RATE,
            "Rate was not updated correctly"
        );

        vm.stopPrank();
    }

    function test_setNativeUsdRate_OnlyFeedUpdater() public {
        vm.startPrank(s_feedUpdater);

        s_conceroPriceFeed.setNativeUsdRate(INITIAL_RATE);
        assertEq(
            s_conceroPriceFeed.getNativeUsdRate(),
            INITIAL_RATE,
            "FeedUpdater should be able to set rate"
        );

        vm.stopPrank();
    }

    function test_setNativeUsdRate_WhenUnauthorized_Reverts() public {
        address unauthorizedUser = address(0x1234);

        vm.startPrank(unauthorizedUser);

        vm.expectRevert(CommonErrors.Unauthorized.selector);
        s_conceroPriceFeed.setNativeUsdRate(INITIAL_RATE);

        vm.stopPrank();
    }

    function test_setNativeUsdRate_StorageVerification() public {
        vm.startPrank(s_feedUpdater);

        s_conceroPriceFeed.setNativeUsdRate(INITIAL_RATE);

        // Verify storage directly
        uint256 storedValue = s_conceroPriceFeed.getNativeUsdRate();

        assertEq(storedValue, INITIAL_RATE, "Storage verification failed");

        vm.stopPrank();
    }
}
