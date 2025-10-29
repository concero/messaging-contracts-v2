// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library ClientStorage {
    bytes32 internal constant CONCERO_CLIENT =
        keccak256(abi.encode(uint256(keccak256(abi.encodePacked("concero.client"))) - 1)) &
            ~bytes32(uint256(0xff));

    struct ConceroClient {
        mapping(address validator => bool isAllowed) isValidatorAllowed;
        uint256 requiredValidatorsCount;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function client() internal pure returns (ConceroClient storage s) {
        bytes32 slot = CONCERO_CLIENT;
        assembly {
            s.slot := slot
        }
    }
}
