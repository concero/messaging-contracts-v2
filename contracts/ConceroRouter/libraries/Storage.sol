// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {GenericStorage} from "../../common/libraries/GenericStorage.sol";

library Namespaces {
    bytes32 internal constant ROUTER =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("ConceroRouter.router.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));

    bytes32 internal constant PRICEFEED =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("ConceroRouter.priceFeed.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));
}

library Storage {
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
        mapping(bytes32 messageId => bool isSent) isMessageSent;
        mapping(address operator => uint256) operatorFeesEarnedNative;
        mapping(bytes32 messageId => bool isProcessed) isMessageProcessed;
        mapping(bytes32 messageId => bytes32 hashSum) receivedMessages;
        mapping(bytes32 messageId => mapping(Protocol => bool)) messageConfirmationsByProtocol;
    }

    struct PriceFeed {
        uint256 nativeUsdRate;
        uint256[50] __var_gap;
        mapping(uint24 dstChainSelector => uint256) lastGasPrices;
        mapping(uint24 dstChainSelector => uint256) nativeNativeRates;
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
