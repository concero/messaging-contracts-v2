// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Constants} from "../Constants.sol";
import {console} from "forge-std/src/console.sol";

library Utils {
    error NotAContract(address target);
    error DelegateCallFailed(bytes response);
    error InvalidNativeUSDRate();

    function safeDelegateCall(address target, bytes memory args) internal returns (bytes memory) {
        require(isContract(target), NotAContract(target));

        (bool success, bytes memory response) = target.delegatecall(args);
        if (!success) {
            revert DelegateCallFailed(response);
        }

        return response;
    }

    /**
     * @notice Checks if the provided address is a contract.
     * @param addr The address to check.
     * @return bool True if the address is a contract, false otherwise.
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function safeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit return data size to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Converts a USD basis points amount to native currency
     * @param bpsUSD The amount in USD basis points
     * @return The equivalent amount in native currency
     */
    function convertUsdBpsToNative(
        uint16 bpsUSD,
        uint256 nativeUSDRate
    ) internal pure returns (uint256) {
        require(nativeUSDRate != 0, InvalidNativeUSDRate());

        uint256 usdAmount = (uint256(bpsUSD) * 1e18) / Constants.BPS_DENOMINATOR;

        uint256 nativeAmount = (usdAmount * 1e18) / nativeUSDRate;

        //        console.logString("BPS USD:");
        //        console.logUint(bpsUSD);
        //
        //        console.logString("Native USD Rate:");
        //        console.logUint(nativeUSDRate);
        //
        //        console.logString("USD Amount:");
        //        console.logUint(usdAmount);
        //
        //        console.logString("Native Amount:");
        //        console.logUint(nativeAmount);

        return nativeAmount;
    }
}
