// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CommonConstants} from "../../common/CommonConstants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {Errors} from "../libraries/Errors.sol";

import {Deposited, DepositWithdrawn} from "../../interfaces/IConceroValidator.sol";

import {CLF} from "./CLF.sol";

abstract contract Validator is CLF {
    using SafeERC20 for IERC20;
    using s for s.Validator;
    using s for s.Relayer;

    function requestMessageReport(
        bytes32 messageId,
        uint24 srcChainSelector,
        bytes memory srcChainData
    ) external returns (bytes32) {
        s.Validator storage validator = s.validator();

        bytes32 clfRequestId = validator.clfRequestIdByMessageId[messageId];
        if (clfRequestId != bytes32(0)) {
            require(
                validator.clfRequestStatus[clfRequestId] == Types.CLFRequestStatus.Failed,
                Errors.MessageAlreadyProcessed()
            );
        }
        return _requestMessageReport(messageId, srcChainSelector, srcChainData);
    }

    function deposit(uint256 amount) external payable {
        emit Deposited(msg.sender, amount);
    }

    function withdrawDeposit(uint256 amount) external returns (bool success) {
        emit DepositWithdrawn(msg.sender, amount);
        return true;
    }

    /* GETTER FUNCTIONS */

    function getDeposit(address relayer) external view returns (uint256) {
        return s.relayer().depositsNative[relayer];
    }

    function getMinimumDeposit() external view returns (uint256) {
        return getCLFCost();
    }
}
