// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Namespaces {
    bytes32 internal constant PRICEFEED =
        keccak256(
            abi.encode(
                uint256(keccak256(abi.encodePacked("conceropricefeed.pricefeed.storage"))) - 1
            )
        ) & ~bytes32(uint256(0xff));
}

library Storage {
    struct PriceFeed {
        uint256 nativeUsdRate;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(uint24 dstChainSelector => uint256) lastGasPrices;
        mapping(uint24 dstChainSelector => uint256) nativeNativeRates;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function priceFeed() internal pure returns (PriceFeed storage s) {
        bytes32 slot = Namespaces.PRICEFEED;
        assembly {
            s.slot := slot
        }
    }
}
