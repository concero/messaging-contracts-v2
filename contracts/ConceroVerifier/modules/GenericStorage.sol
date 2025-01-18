// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {GenericStorage as gs} from "../../common/libraries/GenericStorage.sol";

import {Namespaces} from "../libraries/Storage.sol";

import {Base} from "./Base.sol";

// @notice External handles for interacting with generic StorageLib
abstract contract GenericStorage is Base {
    function _isValidNamespace(bytes32 slot) internal pure returns (bool) {
        return slot == Namespaces.VERIFIER || slot == Namespaces.OPERATOR;
    }

    function getStorage(bytes32 slot, bytes32 key) external view returns (uint256) {
        require(_isValidNamespace(slot), gs.InvalidNamespace());
        return gs._getStorage(slot, key);
    }

    function setStorage(bytes32 slot, bytes32 key, uint256 value) external onlyOwner {
        require(_isValidNamespace(slot), gs.InvalidNamespace());
        gs._setStorage(slot, key, value);
    }

    function setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) external onlyOwner {
        for (uint256 i = 0; i < slots.length; i++) {
            require(_isValidNamespace(slots[i]), gs.InvalidNamespace());
        }
        gs._setStorageBulk(slots, keys, values);
    }
}
