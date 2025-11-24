// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonConstants} from "../CommonConstants.sol";
import {CommonErrors} from "../CommonErrors.sol";

library Utils {
    uint256 public constant PRECOMPILE_CONTRACTS_SPACE = 1024;

    function transferNative(address receiver, uint256 value) internal {
        (bool success, bytes memory data) = receiver.call{value: value}("");
        require(success, CommonErrors.TransferFailed(data));
    }

    // TODO: remove it
    function isEvmAddressValid(bytes memory encodedAddress) internal pure returns (bool) {
        if (encodedAddress.length != 32) return false;

        uint256 uintAddress = abi.decode(encodedAddress, (uint256));
        if (uintAddress > type(uint160).max || uintAddress < PRECOMPILE_CONTRACTS_SPACE) {
            return false;
        }

        return true;
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

    // TODO: move to validator contract
    /**
     * @notice Converts a USD basis points amount to native currency
     * @param bpsUSD The amount in USD basis points
     * @return The equivalent amount in native currency
     */
    function convertUsdBpsToNative(
        uint16 bpsUSD,
        uint256 nativeUSDRate
    ) internal pure returns (uint256) {
        uint256 usdAmount = (uint256(bpsUSD) * 1e18) / CommonConstants.BPS_DENOMINATOR;

        uint256 nativeAmount = (usdAmount * 1e18) / nativeUSDRate;

        return nativeAmount;
    }
}
