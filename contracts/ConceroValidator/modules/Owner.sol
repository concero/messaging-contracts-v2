// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Base} from "contracts/common/Base.sol";
import {IConceroValidator} from "contracts/interfaces/IConceroValidator.sol";
import {Errors} from "../libraries/Errors.sol";
import {IConceroValidator} from "contracts/interfaces/IConceroValidator.sol";
import {Storage as s} from "../libraries/Storage.sol";
import {Utils} from "../../common/libraries/Utils.sol";

abstract contract Owner is Base {
    using s for s.Validator;

    function withdrawValidatorFee(uint256 amount) external onlyOwner {
        s.Validator storage s_validator = s.validator();

        uint256 currentFees = s_validator.totalNativeFees;
        require(amount <= currentFees, Errors.InsufficientFee(amount, currentFees));

        s_validator.totalNativeFees -= amount;

        Utils.transferNative(msg.sender, amount);

        emit IConceroValidator.ValidatorFeeWithdrawn(msg.sender, amount);
    }

    function setGasFeeConfig(
        uint32 vrfMsgReportRequestGasOverhead,
        uint32 clfGasPriceOverEstimationBps,
        uint32 clfCallbackGasOverhead,
        uint32 clfCallbackGasLimit
    ) external onlyOwner {
        s.validator().gasFeeConfig = s.GasFeeConfig(
            vrfMsgReportRequestGasOverhead,
            clfGasPriceOverEstimationBps,
            clfCallbackGasOverhead,
            clfCallbackGasLimit,
            0
        );
    }
}
