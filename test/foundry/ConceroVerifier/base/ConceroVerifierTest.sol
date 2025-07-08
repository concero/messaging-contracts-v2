// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {OperatorSlots, VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {PriceFeedSlots} from "contracts/ConceroPriceFeed/libraries/StorageSlots.sol";
import {Namespaces as VerifierNamespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {Namespaces as PriceFeedNamespaces} from "contracts/ConceroPriceFeed/libraries/Storage.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";
import {TransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroVerifier} from "../../scripts/deploy/DeployConceroVerifier.s.sol";
import {DeployMockCLFRouter} from "../../scripts/deploy/DeployMockCLFRouter.s.sol";
import {DeployConceroPriceFeed} from "../../scripts/deploy/DeployConceroPriceFeed.s.sol";

import {ConceroVerifierBase} from "./ConceroVerifierBase.sol";
import {MockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";

abstract contract ConceroVerifierTest is DeployConceroVerifier, ConceroTest {
    DeployConceroPriceFeed internal priceFeedDeployer;

    function setUp() public virtual override(DeployConceroVerifier, ConceroTest) {
        super.setUp();

        priceFeedDeployer = new DeployConceroPriceFeed();
        address priceFeed = priceFeedDeployer.deploy();
        conceroPriceFeed = ConceroPriceFeed(payable(priceFeed));

        conceroVerifier = ConceroVerifier(payable(deploy()));

        MockCLFRouter(clfRouter).setConsumer(address(conceroVerifier));
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

        vm.stopPrank();
    }

    function _setOperatorFeesEarned() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            VerifierNamespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEES_NATIVE
        );

        conceroVerifier.setStorage(
            VerifierNamespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            OPERATOR_FEES_NATIVE
        );

        vm.stopPrank();
    }

    function _setOperatorDeposits() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            VerifierNamespaces.OPERATOR,
            OperatorSlots.totalDepositsNative,
            bytes32(0),
            OPERATOR_DEPOSIT_NATIVE
        );

        conceroVerifier.setStorage(
            VerifierNamespaces.OPERATOR,
            OperatorSlots.depositsNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_DEPOSIT_NATIVE
        );
        vm.stopPrank();
    }

    function _setOperatorIsRegistered() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            VerifierNamespaces.OPERATOR,
            OperatorSlots.isRegistered,
            bytes32(uint256(uint160(operator))),
            1
        );

        vm.stopPrank();
    }
}
