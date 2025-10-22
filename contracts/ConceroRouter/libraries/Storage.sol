// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library Namespaces {
    bytes32 internal constant ROUTER =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concerorouter.router.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));
}

library Storage {
    struct Router {
        uint256 nonce;
        uint96 conceroMessageFeeInUsd;
        mapping(bytes32 hashSum => IConceroRouter.MessageStatus messageStatus) messageStatus;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(address feeToken => bool isFeeToken) isFeeTokenSupported;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function router() internal pure returns (Router storage s) {
        bytes32 slot = Namespaces.ROUTER;
        assembly {
            s.slot := slot
        }
    }
}
