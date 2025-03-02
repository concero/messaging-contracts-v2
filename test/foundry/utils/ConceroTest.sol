// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";

import {ConceroBaseScript} from "../scripts/ConceroBaseScript.s.sol";
import {DeployMockERC20} from "../scripts/deploy/DeployMockERC20.s.sol";

abstract contract ConceroTest is ConceroBaseScript, Test {
    function setUp() public virtual override {
        super.setUp();
    }
}
