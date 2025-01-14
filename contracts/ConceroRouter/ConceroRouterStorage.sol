// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

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
        uint256[50] __mapping_gap;
    }

    struct PriceFeed {
        uint256 nativeUsdcRate;
        uint256[50] __var_gap;
        mapping(uint24 dstChainSelector => uint256) lastGasPrices;
        mapping(uint24 dstChainSelector => uint256) nativeNativeRates;
        uint256[50] __mapping_gap;
    }

    bytes32 internal constant ROUTER_STORAGE_SLOT = keccak256("concero.router.storage");
    bytes32 internal constant PRICEFEED_STORAGE_SLOT = keccak256("concero.priceFeed.storage");

    function _validateSlot(bytes32 slot) internal pure returns (bool) {
        return slot == ROUTER_STORAGE_SLOT || slot == PRICEFEED_STORAGE_SLOT;
    }

    /* SLOT-BASED STORAGE ACCESS */
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
