// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

error InvalidStorageSlot();
error LengthMismatch();

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

library ConceroRouterStorage {
    struct Router {
        uint256 nonce;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address operator => uint256) operatorFeesEarnedUSDC;
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

    function _resolveSlot(StorageSlot slot) private pure returns (bytes32) {
        if (slot == StorageSlot.Router) {
            return ROUTER_STORAGE_SLOT;
        } else if (slot == StorageSlot.PriceFeed) {
            return PRICEFEED_STORAGE_SLOT;
        } else {
            revert InvalidStorageSlot();
        }
    }

    function _setStorage(StorageSlot slotEnum, bytes32 key, uint256 value) internal {
        bytes32 slot = _resolveSlot(slotEnum);

        if (key == bytes32(0)) {
            // Handle scalar values
            assembly {
                sstore(slot, value)
            }
        } else {
            // Handle mappings
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, key)
                mstore(add(ptr, 0x20), slot)
                let storageSlot := keccak256(ptr, 0x40)
                sstore(storageSlot, value)
            }
        }
    }

    function _setStorageBulk(
        StorageSlot[] memory slotEnums,
        bytes32[] memory keys,
        bytes[] memory values
    ) internal {
        require(slotEnums.length == keys.length && keys.length == values.length, LengthMismatch());

        for (uint256 i = 0; i < slotEnums.length; i++) {
            bytes32 slot = _resolveSlot(slotEnums[i]);
            bytes32 key = keys[i];
            bytes memory value = values[i];

            if (key == bytes32(0)) {
                // Handle scalar values
                assembly {
                    sstore(slot, mload(add(value, 0x20)))
                }
            } else {
                // Handle mappings
                assembly {
                    let ptr := mload(0x40)
                    mstore(ptr, key)
                    mstore(add(ptr, 0x20), slot)
                    let storageSlot := keccak256(ptr, 0x40)
                    sstore(storageSlot, mload(add(value, 0x20)))
                }
            }
        }
    }

    function _getStorage(StorageSlot slotEnum, bytes32 key) internal view returns (uint256 value) {
        bytes32 slot = _resolveSlot(slotEnum);

        if (key == bytes32(0)) {
            // Handle scalar values
            assembly {
                value := sload(slot)
            }
        } else {
            // Handle mappings
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, key)
                mstore(add(ptr, 0x20), slot)
                let storageSlot := keccak256(ptr, 0x40)
                value := sload(storageSlot)
            }
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
