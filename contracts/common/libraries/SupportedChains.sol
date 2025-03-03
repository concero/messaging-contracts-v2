// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library SupportedChains {
    error UnsupportedChainSelector();

    /* MAINNET CHAIN SELECTORS */
    uint24 internal constant CHAIN_SELECTOR_ETHEREUM = 1;
    uint24 internal constant CHAIN_SELECTOR_OPTIMISM = 10;
    uint24 internal constant CHAIN_SELECTOR_POLYGON = 137;
    uint24 internal constant CHAIN_SELECTOR_BASE = 8453;
    uint24 internal constant CHAIN_SELECTOR_ARBITRUM = 42161;
    uint24 internal constant CHAIN_SELECTOR_AVALANCHE = 43114;

    /* TESTNET CHAIN SELECTORS */
    uint24 internal constant CHAIN_SELECTOR_ETHEREUM_SEPOLIA = 11155111;
    uint24 internal constant CHAIN_SELECTOR_OPTIMISM_SEPOLIA = 11155420;
    uint24 internal constant CHAIN_SELECTOR_POLYGON_AMOY = 80002;
    uint24 internal constant CHAIN_SELECTOR_BASE_SEPOLIA = 84532;
    uint24 internal constant CHAIN_SELECTOR_ARBITRUM_SEPOLIA = 421614;
    uint24 internal constant CHAIN_SELECTOR_AVALANCHE_FUJI = 43113;

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
            chainSelector == CHAIN_SELECTOR_ETHEREUM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_POLYGON_AMOY ||
            chainSelector == CHAIN_SELECTOR_BASE_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_ARBITRUM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_AVALANCHE_FUJI
        ) {
            return true;
        }

        return false;
    }

    function getSupportedChainSelectors(
        uint24 chainSelector
    ) internal pure returns (uint24[] memory) {
        uint24[] memory chainSelectors = new uint24[](6);

        if (isMainnet(chainSelector)) {
            chainSelectors[0] = CHAIN_SELECTOR_ETHEREUM;
            chainSelectors[1] = CHAIN_SELECTOR_OPTIMISM;
            chainSelectors[2] = CHAIN_SELECTOR_POLYGON;
            chainSelectors[3] = CHAIN_SELECTOR_BASE;
            chainSelectors[4] = CHAIN_SELECTOR_ARBITRUM;
            chainSelectors[5] = CHAIN_SELECTOR_AVALANCHE;
        } else {
            chainSelectors[0] = CHAIN_SELECTOR_ETHEREUM_SEPOLIA;
            chainSelectors[1] = CHAIN_SELECTOR_OPTIMISM_SEPOLIA;
            chainSelectors[2] = CHAIN_SELECTOR_POLYGON_AMOY;
            chainSelectors[3] = CHAIN_SELECTOR_BASE_SEPOLIA;
            chainSelectors[4] = CHAIN_SELECTOR_ARBITRUM_SEPOLIA;
            chainSelectors[5] = CHAIN_SELECTOR_AVALANCHE_FUJI;
        }

        return chainSelectors;
    }

    function isMainnet(uint24 chainSelector) internal pure returns (bool) {
        return
            chainSelector == CHAIN_SELECTOR_ETHEREUM ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM ||
            chainSelector == CHAIN_SELECTOR_POLYGON ||
            chainSelector == CHAIN_SELECTOR_BASE ||
            chainSelector == CHAIN_SELECTOR_ARBITRUM ||
            chainSelector == CHAIN_SELECTOR_AVALANCHE;
    }

    function isChainSupported(uint24 chainSelector) internal pure returns (bool) {
        return isEVMChain(chainSelector);
    }

    function maxConfirmations(uint24 chainSelector) internal pure returns (uint16) {
        return uint16(100);
    }
}
