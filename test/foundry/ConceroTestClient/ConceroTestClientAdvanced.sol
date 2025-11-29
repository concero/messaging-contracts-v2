// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ClientAdvancedStorage as s} from "contracts/ConceroClient/libraries/ClientAdvancedStorage.sol";
import {ConceroAdvancedClient} from "contracts/ConceroClient/ConceroAdvancedClient.sol";
import {ConceroClientBase} from "contracts/ConceroClient/ConceroClientBase.sol";

contract ConceroTestClientAdvanced is ConceroAdvancedClient {
    using s for s.AdvancedClient;

    constructor(address conceroRouter) ConceroClientBase(conceroRouter) {}

    function _conceroReceive(bytes calldata) internal view override {}

    function setIsRelayerLibAllowed(address relayer, bool allowed) public {
        _setIsRelayerLibAllowed(relayer, allowed);
    }

    function setValidatorWeight(address validator, uint256 weight) public {
        s.advancedClient().validatorWeights[validator] = weight;
    }

    function setRequiredWeight(uint256 requiredWeight) public {
        s.advancedClient().requiredWeight = requiredWeight;
    }
}
