// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Namespaces {
    bytes32 internal constant ROUTER =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concerorouter.router.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));

    bytes32 internal constant OPERATOR =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concerorouter.operator.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));

    bytes32 internal constant PRICEFEED =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concerorouter.pricefeed.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));
}

library Storage {
    enum Protocol {
        ProtocolA,
        ProtocolB,
        ProtocolC,
        ProtocolD,
        ProtocolE
    }

    struct Router {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(bytes32 messageId => bool isSent) isMessageSent;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(bytes32 messageId => bytes32 hashSum) receivedMessages;
        mapping(bytes32 messageId => mapping(Protocol => bool)) messageConfirmationsByProtocol;
        mapping(uint24 chainSelector => bool isSupported) isChainSupported;
        mapping(uint24 chainSelector => bytes32 txHash) lastTxHash;
    }

    struct Operator {
        uint256 totalFeesEarnedNative;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address operator => uint256 feesEarned) feesEarnedNative;
    }

    struct GasFeeConfig {
        uint24 baseChainSelector;
        uint32 gasOverhead;
        uint32 relayerGasLimit;
        uint32 verifierGasLimit;
        uint136 __var_gap;
    }

    struct PriceFeed {
        uint256 nativeUsdRate;
        GasFeeConfig gasFeeConfig;
        uint256[49] __var_gap;
        uint256[50] __array_gap;
        mapping(uint24 dstChainSelector => uint256) lastGasPrices;
        mapping(uint24 dstChainSelector => uint256) nativeNativeRates;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function router() internal pure returns (Router storage s) {
        bytes32 slot = Namespaces.ROUTER;
        assembly {
            s.slot := slot
        }
    }

    function operator() internal pure returns (Operator storage s) {
        bytes32 slot = Namespaces.OPERATOR;
        assembly {
            s.slot := slot
        }
    }

    function priceFeed() internal pure returns (PriceFeed storage s) {
        bytes32 slot = Namespaces.PRICEFEED;
        assembly {
            s.slot := slot
        }
    }

    // @notice wrapper for gas savings
    function getNativeNativeRate(uint24 chainSelector) internal view returns (uint256) {
        return priceFeed().nativeNativeRates[chainSelector];
    }
}
