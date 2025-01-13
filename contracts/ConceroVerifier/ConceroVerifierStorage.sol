// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CLFRequestStatus, ChainType} from "../Interfaces/IConceroVerifier.sol";
import {StorageLib} from "../Libraries/StorageLib.sol";

library ConceroVerifierStorage {
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
        mapping(address operator => mapping(uint24 chainSelector => bytes walletAddress)) walletAddress;
        mapping(ChainType => bytes[] operators) registeredOperators;
    }

    bytes32 internal constant VERIFIER_STORAGE_SLOT = keccak256("concero.verifier.storage");
    bytes32 internal constant OPERATOR_STORAGE_SLOT = keccak256("concero.operator.storage");

    function _validateSlot(bytes32 slot) internal pure returns (bool) {
        return slot == VERIFIER_STORAGE_SLOT || slot == OPERATOR_STORAGE_SLOT;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function verifier() internal pure returns (Verifier storage s) {
        bytes32 slot = VERIFIER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    function operator() internal pure returns (Operator storage s) {
        bytes32 slot = OPERATOR_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /* GENERIC STORAGE ACCESS */
    function _getStorage(bytes32 slot, bytes32 key) internal view returns (uint256 value) {
        return StorageLib._getStorage(slot, key);
    }

    function _setStorage(bytes32 slot, bytes32 key, uint256 value) internal {
        require(_validateSlot(slot), StorageLib.InvalidStorageSlot());
        StorageLib._setStorage(slot, key, value);
    }

    function _setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) internal {
        for (uint256 i = 0; i < slots.length; i++) {
            require(_validateSlot(slots[i]), StorageLib.InvalidStorageSlot());
        }
        StorageLib._setStorageBulk(slots, keys, values);
    }
}
