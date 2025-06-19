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
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";
import {ConceroClientExample} from "contracts/ConceroClient/ConceroClientExample.sol";

import {Namespaces as PriceFeedNamespaces} from "contracts/ConceroPriceFeed/libraries/Storage.sol";
import {PriceFeedSlots} from "contracts/ConceroPriceFeed/libraries/StorageSlots.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroRouter} from "../../scripts/deploy/DeployConceroRouter.s.sol";
import {DeployConceroPriceFeed} from "../../scripts/deploy/DeployConceroPriceFeed.s.sol";

abstract contract ConceroRouterTest is DeployConceroRouter, ConceroTest {
    ConceroClientExample internal conceroClient;
    DeployConceroPriceFeed internal priceFeedDeployer;

    function setUp() public virtual override(DeployConceroRouter, ConceroTest) {
        super.setUp();

        priceFeedDeployer = new DeployConceroPriceFeed();
        address priceFeed = priceFeedDeployer.deploy();
        conceroPriceFeed = ConceroPriceFeed(payable(priceFeed));

        conceroRouter = ConceroRouter(payable(deploy()));
        conceroClient = new ConceroClientExample(payable(conceroRouter));
    }

    function _setPriceFeeds() internal {
        vm.startPrank(deployer);

        conceroPriceFeed.setStorage(
            PriceFeedNamespaces.PRICEFEED,
            PriceFeedSlots.nativeUsdRate,
            bytes32(0),
            NATIVE_USD_RATE
        );

        conceroPriceFeed.setStorage(
            PriceFeedNamespaces.PRICEFEED,
            PriceFeedSlots.lastGasPrices,
            bytes32(uint256(SRC_CHAIN_SELECTOR)),
            LAST_GAS_PRICE
        );

        conceroPriceFeed.setStorage(
            PriceFeedNamespaces.PRICEFEED,
            PriceFeedSlots.nativeNativeRates,
            bytes32(uint256(SRC_CHAIN_SELECTOR)),
            1e18
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
