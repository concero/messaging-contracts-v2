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
import {CLFParams} from "./libraries/Types.sol";

contract ConceroVerifier is IConceroVerifier, CLF, Operator, Owner, GenericStorage {
    constructor(
        uint24 chainSelector,
        address USDC,
        CLFParams memory clfParams
    )
        Base(chainSelector, USDC)
        CLF(
            clfParams.router,
            clfParams.donId,
            clfParams.subscriptionId,
            clfParams.donHostedSecretsVersion,
            clfParams.donHostedSecretsSlotId,
            clfParams.premiumFeeUsdBps,
            clfParams.callbackGasLimit,
            clfParams.requestCLFMessageReportJsCodeHash,
            clfParams.requestOperatorRegistrationJsCodeHash
        )
    {}

    receive() external payable {}

    fallback() external payable {}
}
