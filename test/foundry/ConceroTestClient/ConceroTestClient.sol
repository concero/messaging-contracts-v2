// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroClient} from "../../../contracts/ConceroClient/ConceroClient.sol";

contract ConceroTestClient is ConceroClient {
    constructor(address conceroRouter) ConceroClient(conceroRouter) {}

    function _conceroReceive(bytes calldata) internal override {}
}
