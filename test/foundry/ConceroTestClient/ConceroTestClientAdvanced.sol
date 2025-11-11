// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroAdvancedClient} from "contracts/ConceroClient/ConceroAdvancedClient.sol";
import {ConceroClientBase} from "contracts/ConceroClient/ConceroClientBase.sol";

contract ConceroTestClientAdvanced is ConceroAdvancedClient {
    bool internal s_revertFlag;

    error TestRevert();

    constructor(address conceroRouter) ConceroClientBase(conceroRouter) {}

    function _conceroReceive(bytes calldata) internal view override {
        if (s_revertFlag) {
            revert TestRevert();
        }
    }

    function setIsRelayerAllowed(address relayer, bool allowed) public {
        _setIsRelayerAllowed(relayer, allowed);
    }

    function setRevertFlag(bool revertFlag) public {
        s_revertFlag = revertFlag;
    }
}
