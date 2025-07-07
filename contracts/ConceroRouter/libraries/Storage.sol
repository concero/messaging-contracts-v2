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

    bytes32 internal constant CONFIG =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concerorouter.config.storage"))) - 1)
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
    }

    struct Operator {
        uint256 totalFeesEarnedNative;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address operator => uint256 feesEarned) feesEarnedNative;
    }

    struct GasFeeConfig {
        uint24 baseChainSelector;
        uint32 submitMsgGasOverhead;
        uint32 vrfMsgReportRequestGasLimit;
        uint32 vrfCallbackGasLimit;
        uint136 __var_gap;
    }

    struct Config {
        GasFeeConfig gasFeeConfig;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
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

    function config() internal pure returns (Config storage s) {
        bytes32 slot = Namespaces.CONFIG;
        assembly {
            s.slot := slot
        }
    }
}
