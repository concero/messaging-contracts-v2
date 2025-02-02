// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {DeployConceroVerifier} from "./DeployConceroVerifier.s.sol";
import {DeployConceroRouter} from "./DeployConceroRouter.s.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {ConceroBaseScript} from "./ConceroBaseScript.s.sol";
import {VmSafe, Vm} from "forge-std/src/Vm.sol";
import {Namespaces as RouterNamespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {Namespaces as VerifierNamespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {PriceFeedSlots as routerPFSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {PriceFeedSlots as verifierPFSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

/**
 * @title SetupOperatorAnvil
 * @notice Deploys ConceroVerifier and ConceroRouter, then sets storage values in both.
 */
contract SetupOperatorAnvil is ConceroBaseScript {
    uint256 internal constant CHAIN_SELECTOR = 1;
    uint256 internal constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000
    uint256 internal constant LAST_GAS_PRICE = 1e9; // 1 gwei

    function run() public {
        DeployConceroVerifier verifierDeployer = new DeployConceroVerifier();
        address conceroVerifierAddress = verifierDeployer.run();
        ConceroVerifier conceroVerifier = ConceroVerifier(payable(conceroVerifierAddress));

        DeployConceroRouter routerDeployer = new DeployConceroRouter();
        address conceroRouterAddress = routerDeployer.run();
        ConceroRouter conceroRouter = ConceroRouter(payable(conceroRouterAddress));

        vm.stopBroadcast();
        //        setStorageValues(verifierDeployer, conceroVerifier, conceroRouter);
        //        dealBalances();

        console.logString("ConceroVerifier address:");
        console.logAddress(conceroVerifierAddress);
    }

    function setStorageValues(
        DeployConceroVerifier verifierDeployer,
        ConceroVerifier conceroVerifier,
        ConceroRouter conceroRouter
    ) internal {
        conceroVerifier.setStorage(
            VerifierNamespaces.PRICEFEED,
            verifierPFSlots.nativeUsdRate,
            bytes32(0),
            NATIVE_USD_RATE
        );
        conceroVerifier.setStorage(
            VerifierNamespaces.PRICEFEED,
            verifierPFSlots.lastGasPrices,
            bytes32(CHAIN_SELECTOR),
            LAST_GAS_PRICE
        );
        conceroVerifier.setStorage(
            VerifierNamespaces.PRICEFEED,
            verifierPFSlots.nativeNativeRates,
            bytes32(CHAIN_SELECTOR),
            1e18
        );

        conceroRouter.setStorage(
            RouterNamespaces.PRICEFEED,
            routerPFSlots.nativeUsdRate,
            bytes32(CHAIN_SELECTOR),
            LAST_GAS_PRICE
        );
    }

    function dealBalances() internal {
        address operator = vm.envAddress("TESTNET_OPERATOR_ADDRESS");
        vm.deal(operator, 1000e18);
    }
}
