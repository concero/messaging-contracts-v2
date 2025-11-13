// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

interface IConceroPriceFeed {
    error TokenIsNotSupported(address);

    function getNativeUsdRate() external view returns (uint256);
    function getNativeUsdRateAndGasPrice() external view returns (uint256, uint256);
    function getNativeNativeRate(uint24 chainSelector) external view returns (uint256);
    function getLastGasPrice(uint24 chainSelector) external view returns (uint256);

    function getUsdRate(address token) external view returns (uint256); // TODO: implement it

    function getMessageFeeData(
        uint24 dstChainSelector,
        uint24 baseChainSelector
    )
        external
        view
        returns (
            uint256 nativeUsdRate,
            uint256 dstGasPrice,
            uint256 dstNativeRate,
            uint256 baseGasPrice,
            uint256 baseNativeRate
        );
    function setNativeUsdRate(uint256 rate) external;
    function setNativeNativeRates(
        uint24[] calldata chainSelectors,
        uint256[] calldata rates
    ) external;
    function setLastGasPrices(
        uint24[] calldata chainSelectors,
        uint256[] calldata gasPrices
    ) external;
}
