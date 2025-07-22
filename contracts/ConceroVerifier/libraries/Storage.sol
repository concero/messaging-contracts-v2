// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonTypes} from "../../common/CommonTypes.sol";

import {Types} from "./Types.sol";

library Namespaces {
    bytes32 internal constant VERIFIER =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("conceroverifier.verifier.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));

    bytes32 internal constant OPERATOR =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("conceroverifier.operator.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));

    bytes32 internal constant CONFIG =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("conceroverifier.config.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));
}

library Storage {
    struct Verifier {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(bytes32 => Types.CLFRequestStatus) clfRequestStatus;
        mapping(bytes32 clfRequestId => bool isPending) pendingCLFRequests;
        mapping(bytes32 messageId => bool isPending) pendingMessageReports;
        mapping(uint24 chainSelector => bool isSupported) isChainSupported;
    }

    struct Operator {
        uint256 totalFeesEarnedNative;
        uint256 totalDepositsNative;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(CommonTypes.ChainType => bytes[] operators) registeredOperators;
        mapping(address operator => bool) isRegistered;
        mapping(address operator => uint256 depositAmount) depositsNative;
        mapping(address operator => mapping(CommonTypes.ChainType => bytes walletAddress)) walletAddress;
        mapping(address operator => uint256) feesEarnedNative;
    }

    struct GasFeeConfig {
        uint32 vrfMsgReportRequestGasOverhead;
        uint32 clfGasPriceOverEstimationBps;
        uint32 clfCallbackGasOverhead;
        uint32 clfCallbackGasLimit;
        uint128 __var_gap;
    }

    struct Config {
        GasFeeConfig gasFeeConfig;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function verifier() internal pure returns (Verifier storage s) {
        bytes32 slot = Namespaces.VERIFIER;
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
