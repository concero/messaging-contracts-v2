// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library SupportedChains {
    /* MAINNET CHAIN SELECTORS */
    uint24 constant CHAIN_SELECTOR_ETHEREUM = 1;
    uint24 constant CHAIN_SELECTOR_OPTIMISM = 10;
    uint24 constant CHAIN_SELECTOR_POLYGON = 137;
    uint24 constant CHAIN_SELECTOR_BASE = 8453;
    uint24 constant CHAIN_SELECTOR_ARBITRUM = 42161;
    uint24 constant CHAIN_SELECTOR_AVALANCHE = 43114;

    /* TESTNET CHAIN SELECTORS */
    uint24 constant CHAIN_SELECTOR_ARBITRUM_SEPOLIA = 42162;
    uint24 constant CHAIN_SELECTOR_BASE_SEPOLIA = 8454;
    uint24 constant CHAIN_SELECTOR_OPTIMISM_SEPOLIA = 11;
    uint24 constant CHAIN_SELECTOR_POLYGON_AMOY = 138;

    function isEVMChain(uint24 chainSelector) internal pure returns (bool) {
        /* MAINNET */
        if (
            chainSelector == CHAIN_SELECTOR_ETHEREUM ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM ||
            chainSelector == CHAIN_SELECTOR_POLYGON ||
            chainSelector == CHAIN_SELECTOR_BASE ||
            chainSelector == CHAIN_SELECTOR_ARBITRUM ||
            chainSelector == CHAIN_SELECTOR_AVALANCHE
        ) {
            return true;
        }

        /* TESTNET */
        if (
            chainSelector == CHAIN_SELECTOR_ARBITRUM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_BASE_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_POLYGON_AMOY
        ) {
            return true;
        }

        return false;
    }

    function isChainSupported(uint24 chainSelector) internal pure returns (bool) {
        return isEVMChain(chainSelector);
    }
}
