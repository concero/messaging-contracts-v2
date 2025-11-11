// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";

contract DeployConceroPriceFeed is Script {
    address internal s_conceroPriceFeed;
    address public s_deployer = vm.envAddress("DEPLOYER_ADDRESS");

    function deploy(uint24 srcChainSelector, address feedUpdater) public returns (address) {
        vm.prank(s_deployer);
        s_conceroPriceFeed = address(new ConceroPriceFeed(srcChainSelector, feedUpdater));

        return s_conceroPriceFeed;
    }
}
