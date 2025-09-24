// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {OperatorSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {ConceroRouterHarness} from "contracts/ConceroRouter/ConceroRouterHarness.sol";
import {ConceroClientExample} from "contracts/ConceroClient/ConceroClientExample.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroRouter} from "../../scripts/deploy/DeployConceroRouter.s.sol";

abstract contract ConceroRouterTest is DeployConceroRouter, ConceroTest {
    ConceroClientExample internal conceroClient;

    function setUp() public virtual override(DeployConceroRouter, ConceroTest) {
        super.setUp();

        conceroRouter = ConceroRouterHarness(
            payable(deploy(SRC_CHAIN_SELECTOR, address(conceroPriceFeed)))
        );

        conceroClient = new ConceroClientExample(payable(conceroRouter));
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
