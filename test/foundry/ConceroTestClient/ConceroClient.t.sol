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
import {ConceroTestClient} from "./ConceroTestClient.sol";

contract ConceroClientTestBase is ConceroClientTest {
    function setUp() public override {
        super.setUp();
    }

    function test_conceroReceive_Success() public {
        bytes memory messageReceipt = _buildMessageReceipt();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.prank(address(s_mockConceroRouter));
        s_conceroClient.conceroReceive(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib
        );
    }

    function test_constructor_RevertsIfInvalidConceroRouter() public {
        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.InvalidConceroRouter.selector, address(0))
        );
        new ConceroTestClient(address(0));
    }

    function test_conceroReceive_RevertsIfInvalidConceroRouter() public {
        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.InvalidConceroRouter.selector, address(this))
        );
        s_conceroClient.conceroReceive(new bytes(0), new bool[](0), new address[](0), s_relayerLib);
    }

    function test_conceroReceive_RevertsIfRelayerNotAllowed() public {
        bytes memory messageReceipt = _buildMessageReceipt();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        s_conceroClient.setIsRelayerAllowed(s_relayerLib, false);

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.RelayerNotAllowed.selector, s_relayerLib)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClient.conceroReceive(
            messageReceipt,
            validationChecks,
            new address[](1),
            s_relayerLib
        );
    }

    function test_RequiredMoreValidatorsCount_RevertsIfValidatorsConsensusNotReached() public {
        bytes memory messageReceipt = _buildMessageReceipt();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        s_conceroClient.setRequiredValidatorsCount(2);

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.ValidatorsConsensusNotReached.selector)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClient.conceroReceive(
            messageReceipt,
            validationChecks,
            new address[](0),
            s_relayerLib
        );
    }

    function test_ValidationChecksNotEqualToValidatorsCount_RevertsIfValidatorsConsensusNotReached()
        public
    {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory dstValidatorLibs = new address[](2);
        dstValidatorLibs[0] = s_validatorLib;
        dstValidatorLibs[1] = s_validatorLib;

        bytes memory messageReceipt = _buildMessageReceipt(messageRequest);

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.ValidatorsConsensusNotReached.selector)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClient.conceroReceive(
            messageReceipt,
            validationChecks,
            dstValidatorLibs,
            s_relayerLib
        );
    }

    function test_ValidationCheckIsFalse_RevertsIfValidatorsConsensusNotReached() public {
        bytes memory messageReceipt = _buildMessageReceipt();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = false;

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.ValidatorsConsensusNotReached.selector)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClient.conceroReceive(
            messageReceipt,
            validationChecks,
            new address[](1),
            s_relayerLib
        );
    }

    function test_ValidatorNotAllowed_RevertsIfValidatorsConsensusNotReached() public {
        bytes memory messageReceipt = _buildMessageReceipt();

        s_conceroClient.setIsValidatorAllowed(s_validatorLib, false);

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.ValidatorsConsensusNotReached.selector)
        );

        vm.prank(address(s_mockConceroRouter));
        s_conceroClient.conceroReceive(
            messageReceipt,
            new bool[](0),
            new address[](0),
            s_relayerLib
        );
    }
}
