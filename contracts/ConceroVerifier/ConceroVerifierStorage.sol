// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CLFRequestStatus, ChainType} from "../Interfaces/IConceroVerifier.sol";
import {StorageAccessLib} from "../Libraries/StorageAccessLib.sol";

library ConceroVerifierStorageSlotsVerifier {
    bytes32 internal constant NONCE = bytes32(0);
    bytes32 internal constant CLF_REQUEST_STATUS = keccak256("clfRequestStatus");
    bytes32 internal constant PENDING_CLF_REQUESTS = keccak256("pendingCLFRequests");
    bytes32 internal constant PENDING_MESSAGE_REPORTS = keccak256("pendingMessageReports");
}

library ConceroVerifierStorageSlotsOperator {
    bytes32 internal constant IS_ALLOWED = keccak256("isAllowed");
    bytes32 internal constant DEPOSIT = keccak256("deposit");
    bytes32 internal constant REGISTERED_OPERATORS = keccak256("registeredOperators");
    bytes32 internal constant WALLET_ADDRESS = keccak256("walletAddress");
    bytes32 internal constant FEES_EARNED_NATIVE = keccak256("feesEarnedNative");
    bytes32 internal constant FEES_EARNED_USDC = keccak256("feesEarnedUSDC");
}

library ConceroVerifierStorage {
    /* STORAGE STRUCTS */
    struct Verifier {
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
        mapping(ChainType => bytes[] operators) registeredOperators;
        mapping(address operator => mapping(uint24 chainSelector => bytes walletAddress)) walletAddress;
        mapping(address operator => uint256) feesEarnedNative;
        mapping(address operator => uint256) feesEarnedUSDC;
    }

    bytes32 internal constant VERIFIER_STORAGE_NAMESPACE = keccak256("concero.verifier.storage");
    bytes32 internal constant OPERATOR_STORAGE_NAMESPACE = keccak256("concero.operator.storage");

    function _isValidNamespace(bytes32 slot) internal pure returns (bool) {
        return slot == VERIFIER_STORAGE_NAMESPACE || slot == OPERATOR_STORAGE_NAMESPACE;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function verifier() internal pure returns (Verifier storage s) {
        bytes32 slot = VERIFIER_STORAGE_NAMESPACE;
        assembly {
            s.slot := slot
        }
    }

    function operator() internal pure returns (Operator storage s) {
        bytes32 slot = OPERATOR_STORAGE_NAMESPACE;
        assembly {
            s.slot := slot
        }
    }

    /* GENERIC STORAGE ACCESS */
    function getStorage(bytes32 slot, bytes32 key) internal view returns (uint256) {
        require(_isValidNamespace(slot), StorageAccessLib.InvalidNamespace());
        return StorageAccessLib._getStorage(slot, key);
    }

    function setStorage(bytes32 slot, bytes32 key, uint256 value) internal {
        require(_isValidNamespace(slot), StorageAccessLib.InvalidNamespace());
        StorageAccessLib._setStorage(slot, key, value);
    }

    function setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) internal {
        for (uint256 i = 0; i < slots.length; i++) {
            require(_isValidNamespace(slots[i]), StorageAccessLib.InvalidNamespace());
        }
        StorageAccessLib._setStorageBulk(slots, keys, values);
    }
}
