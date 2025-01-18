// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {GenericStorage} from "../../common/libraries/GenericStorage.sol";

import {Types} from "./Types.sol";

library Namespaces {
    bytes32 internal constant VERIFIER = keccak256("concero.verifier.storage");
    bytes32 internal constant OPERATOR = keccak256("concero.operator.storage");
}

library Storage {
    struct Verifier {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(bytes32 => Types.CLFRequestStatus) clfRequestStatus;
        mapping(bytes32 clfRequestId => bool isPending) pendingCLFRequests;
        mapping(bytes32 messageId => bool isPending) pendingMessageReports;
        uint256[50] __mapping_gap;
    }

    struct Operator {
        mapping(address operator => bool) isAllowed;
        mapping(address operator => uint256 depositUSDC) deposit;
        mapping(Types.ChainType => bytes[] operators) registeredOperators;
        mapping(address operator => mapping(uint24 chainSelector => bytes walletAddress)) walletAddress;
        mapping(address operator => uint256) feesEarnedNative;
        mapping(address operator => uint256) feesEarnedUSDC;
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
}
