// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterHarness} from "../../harnesses/ConceroRouterHarness.sol";
import {PauseDummy} from "contracts/PauseDummy/PauseDummy.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroPriceFeed} from "../deploy/DeployConceroPriceFeed.s.sol";
import {Script} from "forge-std/src/Script.sol";

contract DeployConceroRouter is Script {
    ConceroRouterHarness internal s_conceroRouter;

    address public s_deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address public s_proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");

    function deploy(uint24 chainSelector, address priceFeed) public returns (address) {
        vm.prank(s_deployer);
        s_conceroRouter = new ConceroRouterHarness(chainSelector, priceFeed);

        return address(s_conceroRouter);
    }
}
