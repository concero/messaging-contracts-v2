// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IConceroClient} from "contracts/interfaces/IConceroClient.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {IValidatorLib} from "contracts/interfaces/IValidatorLib.sol";
import {ConceroClientTest} from "./base/ConceroClientTest.sol";
import {ConceroTestClientAdvanced} from "./ConceroTestClientAdvanced.sol";

contract ConceroClientAdvancedTest is ConceroClientTest {
    function setUp() public override {
        super.setUp();
    }

    function test_conceroReceive_Success() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        bytes[] memory dstValidatorLibs = new bytes[](2);
        dstValidatorLibs[0] = IValidatorLib(s_validatorLib).getDstLib(DST_CHAIN_SELECTOR);
        dstValidatorLibs[1] = abi.encodePacked(makeAddr("dstValidatorLib2"));

        bytes memory messageReceipt = _buildMessageReceipt(
            messageRequest,
            IRelayerLib(s_relayerLib).getDstLib(DST_CHAIN_SELECTOR),
            dstValidatorLibs
        );

        bool[] memory validationChecks = new bool[](2);
        validationChecks[0] = true;
        validationChecks[1] = true;

        s_conceroClientAdvanced.setValidatorWeight(s_validatorLib, 1);
        s_conceroClientAdvanced.setValidatorWeight(makeAddr("dstValidatorLib2"), 1);
        s_conceroClientAdvanced.setRequiredWeight(2);

        vm.prank(address(s_mockConceroRouter));
        s_conceroClientAdvanced.conceroReceive(messageReceipt, validationChecks);
    }

    function test_TwoSameValidators_RevertsValidatorsConsensusNotReached() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        bytes[] memory dstValidatorLibs = new bytes[](2);
        dstValidatorLibs[0] = IValidatorLib(s_validatorLib).getDstLib(DST_CHAIN_SELECTOR);
        dstValidatorLibs[1] = IValidatorLib(s_validatorLib).getDstLib(DST_CHAIN_SELECTOR);

        bytes memory messageReceipt = _buildMessageReceipt(
            messageRequest,
            IRelayerLib(s_relayerLib).getDstLib(DST_CHAIN_SELECTOR),
            dstValidatorLibs
        );

        bool[] memory validationChecks = new bool[](2);
        validationChecks[0] = true;
        validationChecks[1] = true;

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.ValidatorsConsensusNotReached.selector)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClientAdvanced.conceroReceive(messageReceipt, validationChecks);
    }

    function test_NotEnoughWeight_RevertsValidatorsConsensusNotReached() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        bytes[] memory dstValidatorLibs = new bytes[](2);
        dstValidatorLibs[0] = IValidatorLib(s_validatorLib).getDstLib(DST_CHAIN_SELECTOR);
        dstValidatorLibs[1] = abi.encodePacked(makeAddr("dstValidatorLib2"));

        bytes memory messageReceipt = _buildMessageReceipt(
            messageRequest,
            IRelayerLib(s_relayerLib).getDstLib(DST_CHAIN_SELECTOR),
            dstValidatorLibs
        );

        bool[] memory validationChecks = new bool[](2);
        validationChecks[0] = true;
        validationChecks[1] = true;

        s_conceroClientAdvanced.setValidatorWeight(makeAddr("dstValidatorLib2"), 1);
        s_conceroClientAdvanced.setRequiredWeight(2);

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.ValidatorsConsensusNotReached.selector)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClientAdvanced.conceroReceive(messageReceipt, validationChecks);
    }
}
