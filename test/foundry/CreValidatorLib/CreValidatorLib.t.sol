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

    address internal s_signer1 = 0x4d7D71C7E584CfA1f5c06275e5d283b9D3176924;
    address internal s_signer2 = 0x1A89c98E75983Ec384AD8e83EAf7D0176eEaF155;
    address internal s_signer3 = 0xdE5CD1dD4300A0b4854F8223add60D20e1dFe21b;
    address internal s_signer4 = 0x4D6CFd44F94408a39fB1af94a53c107A730ba161;
    address internal s_signer5 = 0xF3BAa9A99B5ad64f50779F449Bac83bAAC8bfDb6;
    address internal s_signer6 = 0xD7F22fB5382ff477d2fF5c702cAB0EF8abf18233;
    address internal s_signer7 = 0xcdf20F8FFD41B02c680988b20e68735cc8C1ca17;
    address internal s_signer8 = 0xff9b062fcCb2f042311343048b9518068370F837;
    address internal s_signer9 = 0x4f99b550623e77B807df7cbED9C79D55E1163B48;

    function setUp() public {
        s_validatorLib.initialize(address(this));

        address[] memory signers = new address[](9);
        signers[0] = s_signer1;
        signers[1] = s_signer2;
        signers[2] = s_signer3;
        signers[3] = s_signer4;
        signers[4] = s_signer5;
        signers[5] = s_signer6;
        signers[6] = s_signer7;
        signers[7] = s_signer8;
        signers[8] = s_signer9;

        bool[] memory isAllowedArr = new bool[](signers.length);
        for (uint256 i; i < isAllowedArr.length; ++i) {
            isAllowedArr[i] = true;
        }

        s_validatorLib.setAllowedSigners(signers, isAllowedArr);
        s_validatorLib.setExpectedSignersCount(uint8(signers.length));
        s_validatorLib.setIsWorkflowIdAllowed(
            0x005abdaec2b4e01b66d0b021ecb27d59ccf2868968de657c7ded9c37a3b03a10,
            true
        );
    }

    function test_validateSignatures() public {
        assert(s_validatorLib.isValid(_getMessageReceipt(), _getValidation()));
    }

    // INTERNAL FUNCTIONS

    function _getValidation() internal returns (bytes memory) {
        bytes
            memory signature1 = hex"d205b207538957f496d4fd150b9400f01aadd78f23afd4362c0cd7f2b11527d4233678d5c25f8465b8e73483f70b0b5ac3cf302182d3058c8d5dc4c03223958b00";
        bytes
            memory signature2 = hex"1e73fa764c60b7e809222a28e3d32b1643725aaf9682f02ebd9555c1229b1bac7d2069bd90119bc52d7e1377223e8b2f10c5e7b00c606bd6c074330e4d63686201";
        bytes
            memory signature3 = hex"0d3ed12934b6ca5670d3375a4072ec5d86a916aea42416719c1bc3eb23e851e310e75bce8954a2ac1a38022934fa2bedb256947bc231e7cdfb9d1a899742da7601";
        bytes
            memory signature4 = hex"fd8a2539e83002e233a7c7bd3104a5ae15d807d1618bc7e2839b042687229c15754067f9564cc2ff4c492d935078a97930bf526970125b8681ddba690f9c82e000";
        bytes
            memory signature5 = hex"7ac9e18e54eb585936dc2142694be016c45d8ab74c6fc6e6966fd57be024d0260effc6e69891ec7f3c39c4c3de6cfe979324a6bdf73acea094ee63388d37424600";
        bytes
            memory signature6 = hex"cba99c1f9efc8ca37e537f00ea9a6947ab847fad4a8351672dda44a5d73d9742115fe76410ed85d00dce2941d48607c1a82903772ce5e84a95c0659f70ea59a300";
        bytes
            memory signature7 = hex"f33f62b1a07d8ed0ba9f438b40c446c521f7b79841ec64a5eaf9ebeafc26a8d4759fff490a885f5b618ce2766a6bf2c22bc4b294cf2cc364eee630f11ddf65de01";
        bytes
            memory signature8 = hex"0ae9258d491714311c75c907c905b1751e6756a115ef902a942a0396af7b24c15a241f402f7196a8eaba1aee4daf2755ce0d8db3255da6bea3cbfafaf315e1cc00";
        bytes
            memory signature9 = hex"88702485aeb04af188eec3b34358b14e6fa726bde84ee993ba7f104259584f5f4f884b6baba74b6609c541acf7494afaeaf793188810746b355fc9a2065e5ae101";
        bytes
            memory reportContext = hex"000e8ce31db48e5e44619d24d9dadfc5f22a34db8205b2b25cd831eab02244c50000000000000000000000000000000000000000000000000000000048352a000000000000000000000000000000000000000000000000000000000000000000";
        bytes
            memory rawReport = hex"01115515065110d69856ba0ce52a3993946cfaef9646554f4c5bd166dd4e800ab46929b60e0000000100000001005abdaec2b4e01b66d0b021ecb27d59ccf2868968de657c7ded9c37a3b03a1066666634313464303336dddddb8a8e41c194ac6542a0ad7ba663a72741e00004361850ddbced44d2c34178636e0bb1290024a0979a7ab593fd5c4e99f2a9d616";

        bytes[] memory signatures = new bytes[](9);
        signatures[0] = signature1;
        signatures[1] = signature2;
        signatures[2] = signature3;
        signatures[3] = signature4;
        signatures[4] = signature5;
        signatures[5] = signature6;
        signatures[6] = signature7;
        signatures[7] = signature8;
        signatures[8] = signature9;

        return abi.encodePacked(rawReport, reportContext, abi.encode(signatures));
    }

    function _getMessageReceipt() internal returns (bytes memory) {
        bytes
            memory logData = hex"0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010000000000000000000000000047eff953e7d2706cf0cbdd10f7afca8b4080864a000000000000000000000000000000000000000000000000000000000000007a01013882066eee000000000000000000000000000000000000000000000000000000000000000200001cf4b0e5669bb28c21db33bb184e42ecbecf117ef40000000000000000000018bb87f69a7e5ab2269e21fc78152c2f19908b0a49000493e00000010000000100000000000c48656c6c6f20776f726c6421000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000010310f1414ce4c5d1bbd1c4b8f846ea8985b8d9e";

        (bytes memory messageReceipt, , ) = abi.decode(logData, (bytes, address[], address));
        return messageReceipt;
    }
}
