// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {OperatorSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Namespaces as VerifierNamespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroVerifier} from "../../scripts/deploy/DeployConceroVerifier.s.sol";

import {MockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";

abstract contract ConceroVerifierTest is DeployConceroVerifier, ConceroTest {
    function setUp() public virtual override(DeployConceroVerifier, ConceroTest) {
        super.setUp();

        conceroVerifier = ConceroVerifier(payable(deploy()));

        MockCLFRouter(clfRouter).setConsumer(address(conceroVerifier));
    }

    function _setGasFeeConfig() internal {
        vm.startPrank(deployer);
        conceroVerifier.setGasFeeConfig(
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            CLF_GAS_PRICE_OVER_ESTIMATION_BPS,
            CLF_CALLBACK_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_LIMIT
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
