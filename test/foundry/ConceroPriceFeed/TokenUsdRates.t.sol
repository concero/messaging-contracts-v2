// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroTest} from "../utils/ConceroTest.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";

contract TokenUsdRatesTest is ConceroTest {
    address public constant TOKEN_A = address(0x1);
    address public constant TOKEN_B = address(0x2);
    uint256 public constant RATE_A = 1000e18; // $1000
    uint256 public constant RATE_B = 1e18; // $1
    uint256 public constant UPDATED_RATE = 1500e18; // $1500

    /* Setter Tests */

    function test_setTokenUsdRates_Success() public {
        vm.startPrank(s_feedUpdater);

        address[] memory tokens = new address[](2);
        tokens[0] = TOKEN_A;
        tokens[1] = TOKEN_B;

        uint256[] memory rates = new uint256[](2);
        rates[0] = RATE_A;
        rates[1] = RATE_B;

        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);

        assertEq(s_conceroPriceFeed.getUsdRate(TOKEN_A), RATE_A, "Token A rate incorrect");
        assertEq(s_conceroPriceFeed.getUsdRate(TOKEN_B), RATE_B, "Token B rate incorrect");

        vm.stopPrank();
    }

    function test_setTokenUsdRates_UpdateExisting() public {
        vm.startPrank(s_feedUpdater);

        // Set initial rate
        address[] memory tokens = new address[](1);
        tokens[0] = TOKEN_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);
        assertEq(s_conceroPriceFeed.getUsdRate(TOKEN_A), RATE_A, "Initial rate not set");

        // Update rate
        rates[0] = UPDATED_RATE;
        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);

        assertEq(s_conceroPriceFeed.getUsdRate(TOKEN_A), UPDATED_RATE, "Rate not updated");

        vm.stopPrank();
    }

    function test_setTokenUsdRates_WhenLengthMismatch_Reverts() public {
        vm.startPrank(s_feedUpdater);

        address[] memory tokens = new address[](2);
        tokens[0] = TOKEN_A;
        tokens[1] = TOKEN_B;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        vm.expectRevert(CommonErrors.LengthMismatch.selector);
        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);

        vm.stopPrank();
    }

    function test_setTokenUsdRates_WhenUnauthorized_Reverts() public {
        address unauthorizedUser = address(0x1234);

        vm.startPrank(unauthorizedUser);

        address[] memory tokens = new address[](1);
        tokens[0] = TOKEN_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        vm.expectRevert(CommonErrors.Unauthorized.selector);
        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);

        vm.stopPrank();
    }

    /* Getter Tests */

    function test_getUsdRate_ReturnsNativeRate() public {
        vm.startPrank(s_feedUpdater);

        s_conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);

        uint256 rate = s_conceroPriceFeed.getUsdRate(address(0));

        assertEq(rate, NATIVE_USD_RATE, "Native rate incorrect");

        vm.stopPrank();
    }

    function test_getUsdRate_ReturnsTokenRate() public {
        vm.startPrank(s_feedUpdater);

        address[] memory tokens = new address[](1);
        tokens[0] = TOKEN_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = RATE_A;

        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);

        uint256 rate = s_conceroPriceFeed.getUsdRate(TOKEN_A);

        assertEq(rate, RATE_A, "Token rate incorrect");

        vm.stopPrank();
    }

    function test_getUsdRate_WhenUnsupportedToken_Reverts() public {
        address unsupportedToken = address(0x9999);

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroPriceFeed.getUsdRate(unsupportedToken);
    }

    function test_getUsdRate_WhenZeroRate_Reverts() public {
        vm.startPrank(s_feedUpdater);

        address[] memory tokens = new address[](1);
        tokens[0] = TOKEN_A;

        uint256[] memory rates = new uint256[](1);
        rates[0] = 0;

        s_conceroPriceFeed.setTokenUsdRates(tokens, rates);

        vm.stopPrank();

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroPriceFeed.getUsdRate(TOKEN_A);
    }
}
