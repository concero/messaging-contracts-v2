// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library ConceroRouterStorage {
    struct Router {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address operator => uint256) operatorFeesEarnedUSDC;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        uint256[50] __mapping_gap;
    }

    bytes32 internal constant ROUTER_STORAGE_SLOT = keccak256("concero.router.storage");

    function router() internal pure returns (Router storage s) {
        bytes32 slot = ROUTER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}
