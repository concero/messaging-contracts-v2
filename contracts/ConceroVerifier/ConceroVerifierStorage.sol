// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CLFRequestStatus} from "../Interfaces/IConceroVerifier.sol";

library ConceroVerifierStorage {
    struct Router {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(bytes32 => CLFRequestStatus) clfRequestStatus;
        mapping(bytes32 clfRequestId => bool isPending) pendingCLFRequests;
        mapping(bytes32 messageId => bool isPending) pendingMessageReports;
        uint256[50] __mapping_gap;
    }

    struct Operator {
        mapping(address operator => bool) isAllowed;
        mapping(address operator => uint256 depositUSDC) deposit;
        mapping(uint8 cohort => address[] operator) cohort;
        mapping(address operator => mapping(uint24 chainSelector => bytes walletAddress)) walletAddress;
    }

    bytes32 internal constant ROUTER_STORAGE_SLOT = keccak256("concero.verifier.storage");

    function router() internal pure returns (Router storage s) {
        bytes32 slot = ROUTER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    function operator() internal pure returns (Operator storage s) {
        bytes32 slot = ROUTER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}
