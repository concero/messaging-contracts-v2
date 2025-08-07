// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {TransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";

import {RouterSlots, OperatorSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {ConceroRouterHarness} from "contracts/ConceroRouter/ConceroRouterHarness.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";
import {ConceroClientExample} from "contracts/ConceroClient/ConceroClientExample.sol";

import {Namespaces as PriceFeedNamespaces} from "contracts/ConceroPriceFeed/libraries/Storage.sol";
import {PriceFeedSlots} from "contracts/ConceroPriceFeed/libraries/StorageSlots.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroRouter} from "../../scripts/deploy/DeployConceroRouter.s.sol";
import {DeployConceroPriceFeed} from "../../scripts/deploy/DeployConceroPriceFeed.s.sol";
import {console} from "forge-std/src/Console.sol";

abstract contract ConceroRouterTest is DeployConceroRouter, ConceroTest {
    ConceroClientExample internal conceroClient;
    DeployConceroPriceFeed internal priceFeedDeployer;

    function setUp() public virtual override(DeployConceroRouter, ConceroTest) {
        super.setUp();

        // Deploy ConceroPriceFeed first
        priceFeedDeployer = new DeployConceroPriceFeed();
        address priceFeed = priceFeedDeployer.deploy();
        conceroPriceFeed = ConceroPriceFeed(payable(priceFeed));

        // Deploy ConceroRouter with the actual price feed address
        conceroRouter = ConceroRouterHarness(payable(deploy(SRC_CHAIN_SELECTOR, priceFeed)));

        conceroClient = new ConceroClientExample(payable(conceroRouter));
    }

    function _setPriceFeeds() internal {
        vm.startPrank(feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = SRC_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = LAST_GAS_PRICE;
        uint256[] memory rates = new uint256[](1);
        rates[0] = 1e18;

        conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);

        vm.stopPrank();
    }

    function _setGasFeeConfig() internal {
        vm.startPrank(deployer);
        conceroRouter.setGasFeeConfig(
            SRC_CHAIN_SELECTOR,
            SUBMIT_MSG_GAS_OVERHEAD,
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_OVERHEAD
        );
        vm.stopPrank();
    }

    function _setOperatorFeesEarned() internal {
        vm.startPrank(deployer);

        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEES_NATIVE
        );

        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            OPERATOR_FEES_NATIVE
        );

        vm.stopPrank();
    }
}
