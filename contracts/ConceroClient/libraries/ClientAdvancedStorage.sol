// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library ClientAdvancedStorage {
    bytes32 internal constant ADVANCED_CLIENT =
        keccak256(abi.encode(uint256(keccak256(abi.encodePacked("concero.advanced.client"))) - 1)) &
            ~bytes32(uint256(0xff));

    struct AdvancedClient {
        mapping(address validator => uint256 weight) validatorWeights;
        uint256 requiredWeight;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function advancedClient() internal pure returns (AdvancedClient storage s) {
        bytes32 slot = ADVANCED_CLIENT;
        assembly {
            s.slot := slot
        }
    }
}
