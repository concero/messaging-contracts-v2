// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Storage as s} from "./libraries/Storage.sol";

import {IConceroPriceFeed} from "../interfaces/IConceroPriceFeed.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {CommonErrors} from "../common/CommonErrors.sol";

/**
 * @title ConceroPriceFeed
 * @notice Manages price feeds for Concero protocol
 * @dev Stores native USD rates, native-native rates, and gas prices for different chains
 */
contract ConceroPriceFeed is IConceroPriceFeed {
    using s for s.PriceFeed;

    uint24 internal immutable i_chainSelector;
    address public immutable i_feedUpdater;

    modifier onlyFeedUpdater() {
        require(msg.sender == i_feedUpdater, CommonErrors.Unauthorized());
        _;
    }

    /**
     * @notice Constructor to initialize the contract
     * @param s_feedUpdater The address that will be allowed to update feeds
     */
    constructor(uint24 chainSelector, address s_feedUpdater) {
        require(s_feedUpdater != address(0), CommonErrors.InvalidAddress());

        i_chainSelector = chainSelector;
        i_feedUpdater = s_feedUpdater;
    }

    /**
     * @notice Sets the native USD rate
     * @param rate The new native USD rate in 18 decimals
     */
    function setNativeUsdRate(uint256 rate) external onlyFeedUpdater {
        s.priceFeed().nativeUsdRate = rate;
    }

    /**
     * @notice Sets the USD rate for a specific token
     * @param tokens Array of tokens to set the USD rate for
     * @param rates Array of corresponding USD rates in 18 decimals
     */
    function setTokenUsdRates(
        address[] calldata tokens,
        uint256[] calldata rates
    ) external onlyFeedUpdater {
        require(tokens.length == rates.length, CommonErrors.LengthMismatch());

        s.PriceFeed storage priceFeedStorage = s.priceFeed();

        for (uint256 i = 0; i < tokens.length; i++) {
            priceFeedStorage.tokenUsdRates[tokens[i]] = rates[i];
        }
    }

    /**
     * @notice Sets native-native rates for multiple chains
     * @param chainSelectors Array of chain selectors to update
     * @param rates Array of corresponding native-native rates in 18 decimals
     */
    function setNativeNativeRates(
        uint24[] calldata chainSelectors,
        uint256[] calldata rates
    ) external onlyFeedUpdater {
        require(chainSelectors.length == rates.length, CommonErrors.LengthMismatch());

        s.PriceFeed storage priceFeedStorage = s.priceFeed();

        for (uint256 i = 0; i < chainSelectors.length; i++) {
            priceFeedStorage.nativeNativeRates[chainSelectors[i]] = rates[i];
        }
    }

    /**
     * @notice Sets last gas prices for multiple chains
     * @param chainSelectors Array of chain selectors to update
     * @param gasPrices Array of corresponding gas prices in wei
     */
    function setLastGasPrices(
        uint24[] calldata chainSelectors,
        uint256[] calldata gasPrices
    ) external onlyFeedUpdater {
        require(chainSelectors.length == gasPrices.length, CommonErrors.LengthMismatch());

        s.PriceFeed storage priceFeedStorage = s.priceFeed();

        for (uint256 i = 0; i < chainSelectors.length; i++) {
            priceFeedStorage.lastGasPrices[chainSelectors[i]] = gasPrices[i];
        }
    }

    /**
     * @notice Gets the USD rate
     * @param token The token address to get the USD rate for
     * @dev If zero address is provided, the native USD rate is returned
     * @return The USD rate in 18 decimals
     */
    function getUsdRate(address token) external view returns (uint256) {
        s.PriceFeed storage priceFeedStorage = s.priceFeed();

        if (token == address(0)) {
            return priceFeedStorage.nativeUsdRate;
        }

        if (priceFeedStorage.tokenUsdRates[token] == 0) {
            revert IConceroRouter.UnsupportedFeeToken();
        }

        return priceFeedStorage.tokenUsdRates[token];
    }

    /**
     * @notice Gets the native USD rate
     * @return The current native USD rate in 18 decimals
     */
    function getNativeUsdRate() external view returns (uint256) {
        return s.priceFeed().nativeUsdRate;
    }

    /**
     * @notice Gets the native-native rate for a specific chain
     * @param chainSelector The chain selector to get the rate for
     * @return The native-native exchange rate in 18 decimals
     */
    function getNativeNativeRate(uint24 chainSelector) external view returns (uint256) {
        return s.priceFeed().nativeNativeRates[chainSelector];
    }

    /**
     * @notice Gets the last gas price for a specific chain
     * @param chainSelector The chain selector to get the gas price for
     * @return The last recorded gas price in wei
     */
    function getLastGasPrice(uint24 chainSelector) external view returns (uint256) {
        return s.priceFeed().lastGasPrices[chainSelector];
    }

    /**
     * @notice Gets the native USD rate and the last gas price for the current chain
     * @return nativeUsdRate The native USD rate in 18 decimals
     * @return gasPrice The last recorded gas price in wei
     */
    function getNativeUsdRateAndGasPrice() external view returns (uint256, uint256) {
        s.PriceFeed storage priceFeedStorage = s.priceFeed();
        return (priceFeedStorage.nativeUsdRate, priceFeedStorage.lastGasPrices[i_chainSelector]);
    }

    /**
     * @notice Gets all price feed data needed for message fee calculation in one call
     * @param dstChainSelector The destination chain selector
     * @param baseChainSelector The base chain selector
     * @return nativeUsdRate The native USD rate in 18 decimals
     * @return dstGasPrice The destination chain gas price in wei
     * @return dstNativeRate The destination chain native-native rate in 18 decimals
     * @return baseGasPrice The base chain gas price in wei
     * @return baseNativeRate The base chain native-native rate in 18 decimals
     */
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
        )
    {
        s.PriceFeed storage priceFeedStorage = s.priceFeed();

        nativeUsdRate = priceFeedStorage.nativeUsdRate;
        dstGasPrice = priceFeedStorage.lastGasPrices[dstChainSelector];
        dstNativeRate = priceFeedStorage.nativeNativeRates[dstChainSelector];
        baseGasPrice = priceFeedStorage.lastGasPrices[baseChainSelector];
        baseNativeRate = priceFeedStorage.nativeNativeRates[baseChainSelector];
    }
}
