// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroValidator} from "contracts/interfaces/IConceroValidator.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Utils} from "../../common/libraries/Utils.sol";
import {Errors} from "../libraries/Errors.sol";
import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {CLF} from "./CLF.sol";

abstract contract Validator is CLF, IConceroValidator {
    using s for s.Validator;

    /* Request Message Report */

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

    /* Deposit management */

    function deposit() external payable {
        uint256 minimumDeposit = getCLFCost();
        require(msg.value >= minimumDeposit, Errors.InsufficientDeposit(msg.value, minimumDeposit));

        s.validator().depositsNative[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdrawDeposit(uint256 amount) external {
        s.Validator storage s_validator = s.validator();

        uint256 currentDeposit = s_validator.depositsNative[msg.sender];
        require(amount <= currentDeposit, Errors.InsufficientDeposit(currentDeposit, amount));

        s_validator.depositsNative[msg.sender] = currentDeposit - amount;

        Utils.transferNative(msg.sender, amount);

        emit DepositWithdrawn(msg.sender, amount);
    }

    /* Getters */

    function getDeposit(address relayer) external view returns (uint256) {
        return s.validator().depositsNative[relayer];
    }

    function getMinimumDeposit() external view returns (uint256) {
        return getCLFCost();
    }

    function getWithdrawableValidatorFee() external view returns (uint256) {
        return s.validator().totalNativeFees;
    }
}
