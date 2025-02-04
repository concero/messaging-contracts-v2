// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

// Warning: This library does NOT recognise packed storage variables. Be extra cautious when using this contract.
library GenericStorage {
    error LengthMismatch();
    error InvalidNamespace();

    function _setStorage(
        bytes32 namespace,
        uint256 offset,
        bytes32 mappingKey,
        uint256 value
    ) internal {
        assembly {
            switch mappingKey
            case 0 {
                let slot := add(namespace, offset)
                sstore(slot, value)
            }
            default {
                let ptr := mload(0x40)

                let mappingSlot := add(namespace, offset)

                mstore(ptr, mappingKey)
                mstore(add(ptr, 0x20), mappingSlot)
                let storageSlot := keccak256(ptr, 0x40)

                sstore(storageSlot, value)
            }
        }
    }

    function _setStorageBulk(
        bytes32[] memory namespaces,
        uint256[] memory offsets,
        bytes32[] memory mappingKeys,
        uint256[] memory values
    ) internal {
        require(
            namespaces.length == offsets.length &&
                offsets.length == mappingKeys.length &&
                mappingKeys.length == values.length,
            LengthMismatch()
        );

        for (uint256 i = 0; i < namespaces.length; i++) {
            assembly {
                let namespace := mload(add(namespaces, add(0x20, mul(i, 0x20))))
                let offset := mload(add(offsets, add(0x20, mul(i, 0x20))))
                let mappingKey := mload(add(mappingKeys, add(0x20, mul(i, 0x20))))
                let value := mload(add(values, add(0x20, mul(i, 0x20))))

                switch mappingKey
                case 0 {
                    let slot := add(namespace, offset)
                    sstore(slot, value)
                }
                default {
                    let ptr := mload(0x40)

                    let mappingSlot := add(namespace, offset)

                    mstore(ptr, mappingKey)
                    mstore(add(ptr, 0x20), mappingSlot)
                    let storageSlot := keccak256(ptr, 0x40)

                    sstore(storageSlot, value)
                }
            }
        }
    }

    function _getStorage(
        bytes32 namespace,
        uint256 offset,
        bytes32 mappingKey
    ) internal view returns (uint256 value) {
        assembly {
            switch mappingKey
            case 0 {
                // For non-mapping values, load directly from namespace + offset
                let slot := add(namespace, offset)
                value := sload(slot)
            }
            default {
                // For mappings:
                // 1. The base slot is the namespace itself
                // 2. The mapping position is namespace + offset
                // 3. Final slot is keccak256(mappingKey, keccak256(namespace + offset))

                let ptr := mload(0x40)

                // Calculate mapping's base slot (namespace + offset)
                let mappingSlot := add(namespace, offset)

                // Calculate storage slot for specific key
                mstore(ptr, mappingKey)
                mstore(add(ptr, 0x20), mappingSlot)
                let storageSlot := keccak256(ptr, 0x40)

                value := sload(storageSlot)
            }
        }
    }
}
