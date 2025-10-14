// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ValidatorFeeWithdrawn} from "contracts/interfaces/IConceroValidator.sol";
import {Storage as s} from "../libraries/Storage.sol";
import {Base} from "./Base.sol";

abstract contract Owner is Base {
	using s for s.Validator;
    using s for s.Config;

    function withdrawValidatorFee(uint256 amount) external onlyOwner returns (bool success) {
        emit ValidatorFeeWithdrawn(msg.sender, amount);
        return true;
    }

    function setGasFeeConfig(
        uint32 vrfMsgReportRequestGasOverhead,
        uint32 clfGasPriceOverEstimationBps,
        uint32 clfCallbackGasOverhead,
        uint32 clfCallbackGasLimit
    ) external onlyOwner {
        s.config().gasFeeConfig = s.GasFeeConfig(
            vrfMsgReportRequestGasOverhead,
            clfGasPriceOverEstimationBps,
            clfCallbackGasOverhead,
            clfCallbackGasLimit,
            0
        );
    }
}
