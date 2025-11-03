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
        uint24 result;
        assembly {
            result := mload(add(add(data, 4), start))
        }
        return result;
    }

    function readUint64(bytes memory data, uint256 start) internal pure returns (uint64) {
        // TODO: add validations
        uint24 result;
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

    function writeUint24(bytes memory out, uint256 offset, uint24 value) internal pure {
        assembly {
            let ptr := add(add(out, 32), offset)
            mstore8(ptr, shr(16, value))
            mstore8(add(ptr, 1), shr(8, value))
            mstore8(add(ptr, 2), value)
        }
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
}
