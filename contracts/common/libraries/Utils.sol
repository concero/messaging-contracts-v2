// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "../CommonErrors.sol";

library Utils {
    function transferNative(address receiver, uint256 value) internal {
        (bool success, bytes memory data) = receiver.call{value: value}("");
        require(success, CommonErrors.TransferFailed(data));
    }

    function toDecimals(
        uint256 amount,
        uint8 decimalsFrom,
        uint8 decimalsTo
    ) internal pure returns (uint256) {
        if (decimalsFrom == decimalsTo) return amount;

        if (decimalsTo > decimalsFrom) {
            return amount * (10 ** (decimalsTo - decimalsFrom));
        } else {
            return amount / (10 ** (decimalsFrom - decimalsTo));
        }
    }
}
