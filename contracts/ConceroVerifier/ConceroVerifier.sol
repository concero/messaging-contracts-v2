// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {BaseModule} from "./BaseModule.sol";
import {CLFModule} from "./CLFModule.sol";
import {IConceroVerifier} from "../Interfaces/IConceroVerifier.sol";

contract ConceroVerifier is IConceroVerifier, CLFModule {
    constructor(
        uint24 chainSelector,
        address USDC,
        address clfRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        uint64 clfDonHostedSecretsVersion,
        uint8 clfDonHostedSecretsSlotId,
        bytes32 ethersJsCodeHash,
        bytes32 requestCLFMessageReportJsCodeHash
    )
        BaseModule(chainSelector, USDC)
        CLFModule(
            clfRouter,
            clfDonId,
            clfSubscriptionId,
            clfDonHostedSecretsVersion,
            clfDonHostedSecretsSlotId,
            requestCLFMessageReportJsCodeHash
        )
    {}
}
