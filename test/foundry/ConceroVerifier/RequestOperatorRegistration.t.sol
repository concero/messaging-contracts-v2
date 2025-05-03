// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";

import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";

contract RequestOperatorRegistration is ConceroVerifierTest {
    function setUp() public virtual override {
        super.setUp();

        _setPriceFeeds();
        _setOperatorDeposits();
    }

    function test_requestOperatorRegistration() public returns (bytes32) {
        CommonTypes.ChainType[] memory chainTypes = new CommonTypes.ChainType[](1);
        chainTypes[0] = CommonTypes.ChainType.EVM;

        VerifierTypes.OperatorRegistrationAction[]
            memory operatorActions = new VerifierTypes.OperatorRegistrationAction[](1);
        operatorActions[0] = VerifierTypes.OperatorRegistrationAction.Register;

        bytes[] memory operatorAddresses = new bytes[](1);
        operatorAddresses[0] = abi.encodePacked(address(operator));

        vm.prank(operator);
        bytes32 clfRequestId = conceroVerifier.requestOperatorRegistration(
            chainTypes,
            operatorActions,
            operatorAddresses
        );


        assertTrue(conceroVerifier.getStorage(
            Namespaces.VERIFIER,
            VerifierSlots.CLFRequestStatus,
            clfRequestId
        ) == uint256(VerifierTypes.CLFRequestStatus.Pending));

        return clfRequestId;
    }

    function test_requestOperatorRegistration_RevertOnLengthMismatch() public {
        CommonTypes.ChainType[] memory chainTypes = new CommonTypes.ChainType[](2);
        chainTypes[0] = CommonTypes.ChainType.EVM;
        chainTypes[1] = CommonTypes.ChainType.NON_EVM;

        VerifierTypes.OperatorRegistrationAction[]
            memory operatorActions = new VerifierTypes.OperatorRegistrationAction[](1);
        operatorActions[0] = VerifierTypes.OperatorRegistrationAction.Register;

        bytes[] memory operatorAddresses = new bytes[](1);
        operatorAddresses[0] = abi.encodePacked(address(operator));

        vm.expectRevert(abi.encodeWithSignature("LengthMismatch()"));
        conceroVerifier.requestOperatorRegistration(chainTypes, operatorActions, operatorAddresses);
    }
}
