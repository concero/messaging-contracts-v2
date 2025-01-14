// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {BaseModule} from "./BaseModule.sol";
import {StorageLib} from "../Libraries/StorageLib.sol";
import {ConceroRouterStorage as s} from "./ConceroRouterStorage.sol";

// @notice External handles for interacting with generic StorageLib
abstract contract StorageModule is BaseModule {
    function getStorage(bytes32 slot, bytes32 key) external view returns (uint256) {
        return StorageLib._getStorage(slot, key);
    }

    function setStorage(bytes32 slot, bytes32 key, uint256 value) external onlyOwner {
        require(s._validateSlot(slot), StorageLib.InvalidStorageSlot());
        StorageLib._setStorage(slot, key, value);
    }

    function setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) external onlyOwner {
        for (uint256 i = 0; i < slots.length; i++) {
            require(s._validateSlot(slots[i]), StorageLib.InvalidStorageSlot());
        }
        StorageLib._setStorageBulk(slots, keys, values);
    }
}
