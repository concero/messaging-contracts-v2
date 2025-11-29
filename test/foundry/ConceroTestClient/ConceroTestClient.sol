// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroClient} from "../../../contracts/ConceroClient/ConceroClient.sol";

contract ConceroTestClient is ConceroClient {
    bool internal s_revertFlag;

    error TestRevert();

    constructor(address conceroRouter) ConceroClient(conceroRouter) {}

    function _conceroReceive(bytes calldata) internal view override {
        if (s_revertFlag) {
            revert TestRevert();
        }
    }

    function setIsRelayerLibAllowed(address relayer, bool allowed) public {
        _setIsRelayerLibAllowed(relayer, allowed);
    }

    function setIsValidatorAllowed(address validator, bool allowed) public {
        _setIsValidatorAllowed(validator, allowed);
    }

    function setRequiredValidatorsCount(uint256 requiredValidatorsCount) public {
        _setRequiredValidatorsCount(requiredValidatorsCount);
    }

    function setRevertFlag(bool revertFlag) public {
        s_revertFlag = revertFlag;
    }
}
