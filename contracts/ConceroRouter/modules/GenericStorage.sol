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
    function _validateNamespace(bytes32 slot) internal pure {
        require(slot == Namespaces.ROUTER || slot == Namespaces.PRICEFEED, gs.InvalidNamespace());
    }
    function getStorage(bytes32 slot, bytes32 key) external view returns (uint256) {
        _validateNamespace(slot);
        return gs._getStorage(slot, key);
    }

    function setStorage(bytes32 slot, bytes32 key, uint256 value) external onlyOwner {
        _validateNamespace(slot);
        gs._setStorage(slot, key, value);
    }

    function setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) external onlyOwner {
        for (uint256 i = 0; i < slots.length; i++) {
            _validateNamespace(slots[i]);
        }
        gs._setStorageBulk(slots, keys, values);
    }
}
