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

event Deposited(address indexed relayer, uint256 amount);
event DepositWithdrawn(address indexed relayer, uint256 amount);
event ValidatorFeeWithdrawn(address indexed validator, uint256 amount);

interface IConceroValidator {}
