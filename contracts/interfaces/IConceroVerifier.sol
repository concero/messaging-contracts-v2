// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "../ConceroVerifier/libraries/Types.sol";
import {CommonTypes} from "../common/CommonTypes.sol";

event CLFRequestError(bytes err);

event MessageReport(bytes32 indexed messageId);
event MessageReportRequested(bytes32 indexed messageId);

event OperatorDeregistered(Types.ChainType chainType, bytes operatorAddress);
event OperatorDeposited(address indexed operator, uint256 amount);
event OperatorFeeWithdrawn(address indexed operator, uint256 amount);
event OperatorDepositWithdrawn(address indexed operator, uint256 amount);

event OperatorRegistered(
    address indexed operator,
    CommonTypes.ChainType[] chainTypes,
    Types.OperatorRegistrationAction[] operatorActions
);
event OperatorRegistrationRequested(
    address indexed requester,
    CommonTypes.ChainType[] chainTypes,
    Types.OperatorRegistrationAction[] operatorActions,
    bytes[] operatorAddresses
);

interface IConceroVerifier {}
