// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library StorageLib {
    error LengthMismatch();
    error InvalidStorageSlot();

    function _setStorage(bytes32 slot, bytes32 key, uint256 value) internal {
        if (key == bytes32(0)) {
            assembly {
                sstore(slot, value)
            }
        } else {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, key)
                mstore(add(ptr, 0x20), slot)
                let storageSlot := keccak256(ptr, 0x40)
                sstore(storageSlot, value)
            }
        }
    }

    function _setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) internal {
        require(slots.length == keys.length && keys.length == values.length, LengthMismatch());

        for (uint256 i = 0; i < slots.length; i++) {
            bytes32 slot = slots[i];
            bytes32 key = keys[i];
            bytes memory value = values[i];

            if (key == bytes32(0)) {
                assembly {
                    sstore(slot, mload(add(value, 0x20)))
                }
            } else {
                assembly {
                    let ptr := mload(0x40)
                    mstore(ptr, key)
                    mstore(add(ptr, 0x20), slot)
                    let storageSlot := keccak256(ptr, 0x40)
                    sstore(storageSlot, mload(add(value, 0x20)))
                }
            }
        }
    }

    function _getStorage(bytes32 slot, bytes32 key) internal view returns (uint256 value) {
        if (key == bytes32(0)) {
            assembly {
                value := sload(slot)
            }
        } else {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, key)
                mstore(add(ptr, 0x20), slot)
                let storageSlot := keccak256(ptr, 0x40)
                value := sload(storageSlot)
            }
        }
    }
}
