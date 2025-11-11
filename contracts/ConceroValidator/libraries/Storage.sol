// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "./Types.sol";

library Namespaces {
    bytes32 internal constant VALIDATOR =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("concero.validator.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));
}

library Storage {
    struct Validator {
        uint256 totalNativeFees;
        GasFeeConfig gasFeeConfig;
        uint256[50] __var_gap;
        uint256[50] __array_gap;
        mapping(address s_relayer => uint256 depositAmount) depositsNative;
        mapping(bytes32 clfRequestId => Types.CLFRequestStatus) clfRequestStatus;
        mapping(bytes32 messageId => bytes32 clfRequestId) clfRequestIdByMessageId;
        mapping(uint24 chainSelector => bool isSupported) isChainSupported;
    }

    struct GasFeeConfig {
        uint32 vrfMsgReportRequestGasOverhead;
        uint32 clfGasPriceOverEstimationBps;
        uint32 clfCallbackGasOverhead;
        uint32 clfCallbackGasLimit;
        uint128 __var_gap;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function validator() internal pure returns (Validator storage s) {
        bytes32 slot = Namespaces.VALIDATOR;
        assembly {
            s.slot := slot
        }
    }
}
