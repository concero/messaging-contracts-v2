// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {StorageAccessLib} from "../Libraries/StorageAccessLib.sol";

library ConceroRouterStorageSlotsRouter {
    bytes32 internal constant NONCE = bytes32(0);
    bytes32 internal constant OPERATOR_FEES_EARNED_USDC = keccak256("operatorFeesEarnedUSDC");
    bytes32 internal constant OPERATOR_FEES_EARNED_NATIVE = keccak256("operatorFeesEarnedNative");
    bytes32 internal constant IS_MESSAGE_PROCESSED = keccak256("isMessageProcessed");
    bytes32 internal constant IS_MESSAGE_SENT = keccak256("isMessageSent");
    bytes32 internal constant RECEIVED_MESSAGES = keccak256("receivedMessages");
    bytes32 internal constant MESSAGE_CONFIRMATIONS_BY_PROTOCOL =
        keccak256("messageConfirmationsByProtocol");
}

library ConceroRouterStorageSlotsPriceFeed {
    bytes32 internal constant NATIVE_USDC_RATE = bytes32(0);
    bytes32 internal constant LAST_GAS_PRICES = keccak256("lastGasPrices");
    bytes32 internal constant NATIVE_NATIVE_RATES = keccak256("nativeNativeRates");
}

library ConceroRouterStorage {
    enum StorageSlot {
        Router,
        PriceFeed
    }

    enum Protocol {
        ProtocolA,
        ProtocolB,
        ProtocolC,
        ProtocolD,
        ProtocolE
    }

    /* STORAGE STRUCTS */
    struct Router {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address operator => uint256) operatorFeesEarnedUSDC;
        mapping(address operator => uint256) operatorFeesEarnedNative;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(bytes32 messageId => bool isSent) isMessageSent;
        mapping(bytes32 messageId => bytes32 hashSum) receivedMessages;
        mapping(bytes32 messageId => mapping(Protocol => bool)) messageConfirmationsByProtocol;
    }

    struct PriceFeed {
        uint256 nativeUsdcRate;
        uint256[50] __var_gap;
        mapping(uint24 dstChainSelector => uint256) lastGasPrices;
        mapping(uint24 dstChainSelector => uint256) nativeNativeRates;
    }

    bytes32 internal constant ROUTER_STORAGE_NAMESPACE = keccak256("concero.router.storage");
    bytes32 internal constant PRICEFEED_STORAGE_NAMESPACE = keccak256("concero.priceFeed.storage");

    function _isValidNamespace(bytes32 slot) internal pure returns (bool) {
        return slot == ROUTER_STORAGE_NAMESPACE || slot == PRICEFEED_STORAGE_NAMESPACE;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function router() internal pure returns (Router storage s) {
        bytes32 slot = ROUTER_STORAGE_NAMESPACE;
        assembly {
            s.slot := slot
        }
    }

    function priceFeed() internal pure returns (PriceFeed storage s) {
        bytes32 slot = PRICEFEED_STORAGE_NAMESPACE;
        assembly {
            s.slot := slot
        }
    }

    /* GENERIC STORAGE ACCESS */
    function getStorage(bytes32 slot, bytes32 key) internal view returns (uint256) {
        require(_isValidNamespace(slot), StorageAccessLib.InvalidNamespace());
        return StorageAccessLib._getStorage(slot, key);
    }

    function setStorage(bytes32 slot, bytes32 key, uint256 value) internal {
        require(_isValidNamespace(slot), StorageAccessLib.InvalidNamespace());
        StorageAccessLib._setStorage(slot, key, value);
    }

    function setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) internal {
        for (uint256 i = 0; i < slots.length; i++) {
            require(_isValidNamespace(slots[i]), StorageAccessLib.InvalidNamespace());
        }
        StorageAccessLib._setStorageBulk(slots, keys, values);
    }

    /* PriceFeed Storage Setters */
    // function setLastGasPrices(
    //     uint24[] calldata keys,
    //     uint256[] calldata values
    // ) internal  {
    //     require(keys.length == values.length, LengthMismatch());
    //     PriceFeed storage s = priceFeed();

    //     for (uint256 i = 0; i < keys.length; i++) {
    //         s.lastGasPrices[keys[i]] = values[i];
    //     }
    // }

    // function setNativeNativeRates(
    //     uint24[] calldata keys,
    //     uint256[] calldata values
    // ) internal {
    //     require(keys.length == values.length, LengthMismatch());
    //     PriceFeed storage s = priceFeed();

    //     for (uint256 i = 0; i < keys.length; i++) {
    //         s.nativeNativeRates[keys[i]] = values[i];
    //     }
    // }

    // function setNativeUsdcRate(uint256 rate) internal {
    //     priceFeed().nativeUsdcRate = rate;
    // }
}
