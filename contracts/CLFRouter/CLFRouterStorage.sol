// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CLFRequestStatus, Protocol} from "../Interfaces/ICLFRouter.sol";

library CLFRouterStorage {
    struct Router {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address => bool) isAllowedOperator; // Track allowed operators
        mapping(bytes32 => bool) isMessageSent; // Track sent messages
        mapping(bytes32 => bytes32) receivedMessages; // Track received message hashes
        mapping(bytes32 => mapping(Protocol => bool)) protocolConfirmations; // Protocol confirmations
        mapping(bytes32 => CLFRequestStatus) clfRequestStatus; // CLF request status
        uint256[50] __mapping_gap;
    }

    struct PriceFeed {
        uint256 latestLinkUsdcRate;
        uint256 latestNativeUsdcRate;
        uint256 latestLinkNativeRate;
        uint256[50] __var_gap; // Reserved gap for future uint variables
        mapping(uint64 => uint256) lastGasPrices; // Gas prices for different chains
        uint256[50] __mapping_gap; // Reserved gap for future mapping variables
    }

    bytes32 internal constant ROUTER_STORAGE_SLOT = keccak256("concero.coreRouter.storage");
    bytes32 internal constant PRICEFEED_STORAGE_SLOT = keccak256("concero.priceFeed.storage");

    function router() internal pure returns (Router storage s) {
        bytes32 slot = ROUTER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    function priceFeed() internal pure returns (PriceFeed storage s) {
        bytes32 slot = PRICEFEED_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}
