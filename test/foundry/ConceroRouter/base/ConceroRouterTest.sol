// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterHarness} from "../../harnesses/ConceroRouterHarness.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroRouter} from "../../scripts/deploy/DeployConceroRouter.s.sol";
import {ConceroTestClient} from "../../ConceroTestClient/ConceroTestClient.sol";

abstract contract ConceroRouterTest is ConceroTest {
    ConceroTestClient internal s_conceroClient;
    ConceroRouterHarness internal s_conceroRouter;

    function setUp() public virtual {
        s_conceroRouter = ConceroRouterHarness(
            payable(
                (new DeployConceroRouter()).deploy(SRC_CHAIN_SELECTOR, address(s_conceroPriceFeed))
            )
        );

        s_conceroClient = new ConceroTestClient(payable(s_conceroRouter));
    }
}
