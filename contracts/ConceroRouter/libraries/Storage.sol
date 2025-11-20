// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library Storage {
    bytes32 internal constant ROUTER =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concerorouter.router.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));

    struct FeeTokenConfig {
        bool isSupported;
        uint8 decimals;
    }

    struct Router {
        uint96 conceroMessageFeeInUsd; // @dev always has NATIVE_DECIMALS decimals
        uint16 maxValidatorsCount;
        mapping(address feeToken => FeeTokenConfig feeTokenConfig) feeTokenConfigs;
        mapping(address sender => mapping(uint24 srcChainSelector => mapping(uint24 dstChainSelector => uint256 nonce))) nonce;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(bytes32 messageSubmissionHash => bool isAllowed) isMessageRetryAllowed;
        mapping(address feeToken => uint256 totalFeeEarned) totalRelayerFeeEarned;
        mapping(address relayerLib => mapping(address feeToken => uint256 feeEarned)) relayerFeeEarned;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function router() internal pure returns (Router storage s) {
        bytes32 slot = ROUTER;
        assembly {
            s.slot := slot
        }
    }
}
