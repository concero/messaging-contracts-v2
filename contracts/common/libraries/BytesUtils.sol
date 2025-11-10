// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

library BytesUtils {
    function readUint8(bytes memory data, uint256 start) internal pure returns (uint8) {
        // TODO: add validations
        uint8 result;
        assembly {
            result := mload(add(add(data, 1), start))
        }
        return result;
    }

    // @dev implementation: https://etherscan.io/address/0x4bf681894abec828b212c906082b444ceb2f6cf6?#code#F20#L160
    function readUint24(bytes memory data, uint256 start) internal pure returns (uint24) {
        // TODO: add validations
        uint24 result;
        assembly {
            result := mload(add(add(data, 3), start))
        }
        return result;
    }

    function readUint32(bytes memory data, uint256 start) internal pure returns (uint32) {
        // TODO: add validations
        uint32 result;
        assembly {
            result := mload(add(add(data, 4), start))
        }
        return result;
    }

    function readUint64(bytes memory data, uint256 start) internal pure returns (uint64) {
        // TODO: add validations
        uint64 result;
        assembly {
            result := mload(add(add(data, 8), start))
        }
        return result;
    }

    function readUint256(bytes memory data, uint256 start) internal pure returns (uint256) {
        // TODO: add validations
        uint256 result;
        assembly {
            result := mload(add(add(data, 32), start))
        }
        return result;
    }

    // @dev implementation: https://etherscan.io/address/0x4bf681894abec828b212c906082b444ceb2f6cf6?#code#F20#L160
    function readAddress(bytes memory data, uint256 start) internal pure returns (address) {
        // TODO: add validations
        address res;
        assembly {
            res := div(mload(add(add(data, 0x20), start)), 0x1000000000000000000000000)
        }
        return res;
    }

    function writeUint24(
        bytes memory out,
        uint256 offset,
        uint24 value
    ) internal pure returns (uint256) {
        assembly {
            let ptr := add(add(out, 32), offset)
            mstore8(ptr, shr(16, value))
            mstore8(add(ptr, 1), shr(8, value))
            mstore8(add(ptr, 2), value)
        }
        return offset + 3;
    }

    function writeUint32(bytes memory out, uint256 offset, uint32 value) internal pure {
        assembly {
            let ptr := add(add(out, 32), offset)
            mstore8(ptr, shr(24, value))
            mstore8(add(ptr, 1), shr(16, value))
            mstore8(add(ptr, 2), shr(8, value))
            mstore8(add(ptr, 3), value)
        }
    }

    function writeBytes(
        bytes memory out,
        uint256 offset,
        bytes memory src
    ) internal pure returns (uint256) {
        uint256 srcLen = src.length;
        if (srcLen == 0) return offset;

        assembly {
            let dstPtr := add(add(out, 32), offset)
            let srcPtr := add(src, 32)

            for {
                let end := add(srcPtr, and(not(31), srcLen))
            } lt(srcPtr, end) {
                srcPtr := add(srcPtr, 32)
                dstPtr := add(dstPtr, 32)
            } {
                mstore(dstPtr, mload(srcPtr))
            }

            let rem := and(srcLen, 31)
            if rem {
                let mask := sub(shl(mul(8, sub(32, rem)), 1), 1)
                let srcWord := mload(srcPtr)
                let dstWord := mload(dstPtr)
                mstore(dstPtr, or(and(dstWord, mask), and(srcWord, not(mask))))
            }
        }

        return offset + srcLen;
    }

    function calculateTotalFlatBytesArrayLength(
        bytes[] memory data,
        uint256 lengthBytesSize
    ) internal pure returns (uint256 totalLength) {
        uint256 dataLength = data.length;

        assembly {
            totalLength := lengthBytesSize
            let dataPtr := add(data, 0x20)

            for {
                let i := 0
            } lt(i, dataLength) {
                i := add(i, 1)
            } {
                let elementPtr := mload(add(dataPtr, mul(i, 0x20)))
                let elementLength := mload(elementPtr)
                totalLength := add(totalLength, add(elementLength, lengthBytesSize))
            }
        }
    }
}
