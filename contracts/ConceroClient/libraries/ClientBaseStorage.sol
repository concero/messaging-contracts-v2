// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

library ClientBaseStorage {
    bytes32 internal constant CLIENT_BASE =
        keccak256(abi.encode(uint256(keccak256(abi.encodePacked("concero.client.base"))) - 1)) &
            ~bytes32(uint256(0xff));

    struct ConceroClientBase {
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(bytes relayer => bool isAllowed) isRelayerAllowed;
    }

    function clientBase() internal pure returns (ConceroClientBase storage s) {
        bytes32 slot = CLIENT_BASE;
        assembly {
            s.slot := slot
        }
    }
}
