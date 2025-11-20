// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

contract MockPriceFeed {
    function getNativeUsdRate() external pure returns (uint256) {
        return 0;
    }

    function getNativeNativeRate(uint24 chainSelector) external pure returns (uint256) {
        return 0;
    }

    function getLastGasPrice(uint24 chainSelector) external pure returns (uint256) {
        return 0;
    }

    function getUsdRate(address token) external pure returns (uint256) {
        return 1;
    }
}
