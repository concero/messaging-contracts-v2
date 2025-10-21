// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library Storage {
    bytes32 internal constant CONCERO_CLIENT =
        keccak256(abi.encode(uint256(keccak256(abi.encodePacked("concero.client.storage"))) - 1)) &
            ~bytes32(uint256(0xff));

    struct ConceroClient {
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(uint8 messageType => mapping(bytes relayer => bool isAllowed)) isRelayerAllowed;
        mapping(uint8 messageType => mapping(bytes validator => uint256 weight)) validatorWeights;
        mapping(uint8 messageType => uint256 requiredWeight) requiredWeights;
        mapping(uint8 messageType => mapping(uint24 srcChainSelector => mapping(bytes32 expectedSrcChainDataHash => bool isAllowed))) isSrcChainDataAllowed;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function conceroClient() internal pure returns (ConceroClient storage s) {
        bytes32 slot = CONCERO_CLIENT;
        assembly {
            s.slot := slot
        }
    }
}
