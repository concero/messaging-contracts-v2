// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {GenericStorage} from "../../common/libraries/GenericStorage.sol";

library Namespaces {
    bytes32 internal constant ROUTER = keccak256("concero.router.storage");
    bytes32 internal constant PRICEFEED = keccak256("concero.priceFeed.storage");
}

library Storage {
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

    function _isValidNamespace(bytes32 slot) internal pure returns (bool) {
        return slot == Namespaces.ROUTER || slot == Namespaces.PRICEFEED;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function router() internal pure returns (Router storage s) {
        bytes32 slot = Namespaces.ROUTER;
        assembly {
            s.slot := slot
        }
    }

    function priceFeed() internal pure returns (PriceFeed storage s) {
        bytes32 slot = Namespaces.PRICEFEED;
        assembly {
            s.slot := slot
        }
    }

    /* GENERIC STORAGE ACCESS */
    function getStorage(bytes32 slot, bytes32 key) internal view returns (uint256) {
        require(_isValidNamespace(slot), GenericStorage.InvalidNamespace());
        return GenericStorage._getStorage(slot, key);
    }

    function setStorage(bytes32 slot, bytes32 key, uint256 value) internal {
        require(_isValidNamespace(slot), GenericStorage.InvalidNamespace());
        GenericStorage._setStorage(slot, key, value);
    }

    function setStorageBulk(
        bytes32[] memory slots,
        bytes32[] memory keys,
        bytes[] memory values
    ) internal {
        for (uint256 i = 0; i < slots.length; i++) {
            require(_isValidNamespace(slots[i]), GenericStorage.InvalidNamespace());
        }
        GenericStorage._setStorageBulk(slots, keys, values);
    }

    /* PriceFeed GenericStorage.sol Setters */
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
