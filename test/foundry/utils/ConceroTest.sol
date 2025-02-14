// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";

import {ConceroBaseScript} from "../scripts/ConceroBaseScript.s.sol";

abstract contract ConceroTest is Test, ConceroBaseScript {}
