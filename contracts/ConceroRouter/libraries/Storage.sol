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

    struct Router {
        uint96 conceroMessageFeeInUsd;
        uint16 maxValidatorsCount;
        uint64 maxMessageSize;
        mapping(uint24 chainSelector => mapping(address sender => uint256 nonce)) nonce;
        mapping(address feeToken => bool isFeeToken) isFeeTokenSupported;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(bytes32 messageSubmissionHash => bool isAllowed) isMessageRetryAllowed;
        mapping(address feeToken => uint256 totalFeeEarned) totalRelayerFeeEarned;
        mapping(address relayerLib => mapping(address feeToken => uint256 feeEarned)) relayerFeeEarned;
        mapping(address feeToken => address priceFeed) priceFeeds;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function router() internal pure returns (Router storage s) {
        bytes32 slot = ROUTER;
        assembly {
            s.slot := slot
        }
    }
}
