// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {Test} from "forge-std/src/Test.sol";

contract Test_logs is Test {
    event Test_log(bytes indexed data);

    function test_Logs() public {
        bytes memory data = new bytes(5);

        emit Test_log(data);
    }
}
