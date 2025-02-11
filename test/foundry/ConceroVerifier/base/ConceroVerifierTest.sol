// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OperatorSlots, VerifierSlots, PriceFeedSlots} from "../../../../contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Namespaces} from "../../../../contracts/ConceroVerifier/libraries/Storage.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {ConceroVerifier} from "../../../../contracts/ConceroVerifier/ConceroVerifier.sol";
import {DeployConceroVerifier} from "../../scripts/deploy/DeployConceroVerifier.s.sol";
import {TransparentUpgradeableProxy} from "../../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {ConceroVerifierBase} from "./ConceroVerifierBase.sol";
import {console} from "forge-std/src/Console.sol";
abstract contract ConceroVerifierTest is ConceroVerifierBase, ConceroTest {
    DeployConceroVerifier internal deployScript;
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    function setUp() public virtual {
        deployScript = new DeployConceroVerifier();
        address deployedProxy = deployScript.run();

        conceroVerifierProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroVerifier = ConceroVerifier(payable(deployScript.getProxy()));

        usdc = deployScript.usdc();
        clfRouter = deployScript.clfRouter();
    }

    function _setPriceFeeds() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.nativeUsdRate,
            bytes32(0),
            NATIVE_USD_RATE
        );

        conceroVerifier.setStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.lastGasPrices,
            bytes32(uint256(SRC_CHAIN_SELECTOR)),
            LAST_GAS_PRICE
        );

        conceroVerifier.setStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.nativeNativeRates,
            bytes32(uint256(SRC_CHAIN_SELECTOR)),
            1e18
        );

        vm.stopPrank();
    }

    function _setOperatorFeesEarned() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEES_NATIVE
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            OPERATOR_FEES_NATIVE
        );

        vm.stopPrank();
    }

    function _setOperatorDeposits() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalDepositsNative,
            bytes32(0),
            OPERATOR_DEPOSIT_NATIVE
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.depositsNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_DEPOSIT_NATIVE
        );
        vm.stopPrank();
    }

    function _setOperatorIsAllowed() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.isAllowed,
            bytes32(uint256(uint160(operator))),
            1
        );

        vm.stopPrank();
    }
}
