// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {CreValidatorLib} from "../../../contracts/validators/CreValidatorLib/CreValidatorLib.sol";

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

    //    function test_validateSignatures() public {
    //        bytes memory messageReceipt;
    //        bytes memory validation;
    //
    //        s_validatorLib.isValid(messageReceipt, validation);
    //    }
}
