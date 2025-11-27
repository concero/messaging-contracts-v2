// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {CreValidatorLib} from "../../../contracts/validators/CreValidatorLib/CreValidatorLib.sol";

import {console} from "forge-std/src/console.sol";

contract CreValidatorLibTest is Test {
    CreValidatorLib internal s_validatorLib = new CreValidatorLib();

    function setUp() public {
        s_validatorLib.initialize(address(this));

        address[] memory signers = new address[](4);
        signers[0] = makeAddr("signer1");
        signers[1] = makeAddr("signer2");
        signers[2] = makeAddr("signer3");
        signers[3] = makeAddr("signer4");

        bool[] memory isAllowedArr = new bool[](4);
        isAllowedArr[0] = true;
        isAllowedArr[1] = true;
        isAllowedArr[2] = true;
        isAllowedArr[3] = true;

        s_validatorLib.setAllowedSigners(signers, isAllowedArr);
    }

    function test_validateSignatures() public {
        console.logBytes32(keccak256(_getMessageReceipt()));

        assert(s_validatorLib.isValid(_getMessageReceipt(), _getValidation()));
    }

    function _getValidation() internal returns (bytes memory) {
        bytes
            memory signature1 = hex"67a0e0de4498c29c12a9cda294e78d311ad60f81a53f06bb902e80999381f962076e980ab11d508218c7d659013cc048a965d54d269d62b3339e8237c51d671201";
        bytes
            memory signature2 = hex"0267fede8430ddcf36ed4c0850be3fa5d651937bc0bccdc7dc12839cd628a860088600d34ab24b16b0b9fe4dd2a08ef3aef65a325e819a0ca9549845b54497a301";
        bytes
            memory reportContext = hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f00000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000";
        bytes
            memory rawReport = hex"0133317d48575741e79956a801306cdc72f9592f9e7745057a1488ccb2c4022665000000640000000100000001111111111111111111111111111111111111111111111111111111111111111139313961303433386330aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0001d31f7cd7df1c7fae397757bcd1bd1dd9c7f9f1eebadb9dba774edddf6f367b7f3af3d736d5fdf8f396f671fdb77bdd1be3";

        return abi.encodePacked(rawReport, reportContext, abi.encode(signature1, signature2));
    }

    function _getMessageReceipt() internal returns (bytes memory) {
        bytes
            memory logData = hex"0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010000000000000000000000000047eff953e7d2706cf0cbdd10f7afca8b4080864a000000000000000000000000000000000000000000000000000000000000007701013882066eee000000000000000000000000000000000000000000000000000000000000000300001c98788b0ed1abd57abaa718f44616593cb171144f000000000000000000001883ab7c56b42e9baf0c73f1dc53363f63a33bc33f000493e00000010000000000000c48656c6c6f20776f726c64210000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        (bytes memory messageReceipt, , ) = abi.decode(logData, (bytes, address[], address));
        return messageReceipt;
    }
}
