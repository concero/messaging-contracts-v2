// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroVerifier} from "../interfaces/IConceroVerifier.sol";

import {Base} from "./modules/Base.sol";
import {CLF} from "./modules/CLF.sol";
import {GenericStorage} from "./modules/GenericStorage.sol";
import {Operator} from "./modules/Operator.sol";
import {Owner} from "./modules/Owner.sol";

contract ConceroVerifier is IConceroVerifier, CLF, Operator, Owner, GenericStorage {
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
        Base(chainSelector, USDC)
        CLF(
            clfRouter,
            clfDonId,
            clfSubscriptionId,
            clfDonHostedSecretsVersion,
            clfDonHostedSecretsSlotId,
            requestCLFMessageReportJsCodeHash
        )
    {}

    receive() external payable {}

    fallback() external payable {}
}
