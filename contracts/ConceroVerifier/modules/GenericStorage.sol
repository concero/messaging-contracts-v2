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
        require(
            slot == Namespaces.VERIFIER ||
                slot == Namespaces.OPERATOR ||
                slot == Namespaces.CONFIG,
            gs.InvalidNamespace()
        );
    }

    function getStorage(
        bytes32 namespace,
        uint256 offset,
        bytes32 mappingKey
    ) external view returns (uint256) {
        _validateNamespace(namespace);
        return gs._getStorage(namespace, offset, mappingKey);
    }

    function setStorage(
        bytes32 namespace,
        uint256 offset,
        bytes32 mappingKey,
        uint256 value
    ) external onlyOwner {
        _validateNamespace(namespace);
        gs._setStorage(namespace, offset, mappingKey, value);
    }

    function setStorageBulk(
        bytes32[] memory namespaces,
        uint256[] memory offsets,
        bytes32[] memory mappingKeys,
        uint256[] memory values
    ) external onlyOwner {
        for (uint256 i = 0; i < namespaces.length; i++) {
            _validateNamespace(namespaces[i]);
        }
        gs._setStorageBulk(namespaces, offsets, mappingKeys, values);
    }
}
