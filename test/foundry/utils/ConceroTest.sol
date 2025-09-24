// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {DeployConceroPriceFeed} from "../scripts/deploy/DeployConceroPriceFeed.s.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";

import {ConceroBaseScript} from "../scripts/ConceroBaseScript.s.sol";
import {DeployMockERC20} from "../scripts/deploy/DeployMockERC20.s.sol";

abstract contract ConceroTest is ConceroBaseScript, Test {
    DeployConceroPriceFeed internal priceFeedDeployer;

    function setUp() public virtual override {
        super.setUp();

        priceFeedDeployer = new DeployConceroPriceFeed();
        address priceFeed = priceFeedDeployer.deploy();
        conceroPriceFeed = ConceroPriceFeed(payable(priceFeed));
    }

    function _setPriceFeeds() internal {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = SRC_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = LAST_GAS_PRICE;

        conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        vm.stopPrank();
    }
}
