// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";

contract SendMessage is ConceroRouterTest {
    function setUp() public override {
        super.setUp();
    }

    function test_conceroSendNativeFee_gas() public {
        vm.pauseGasMetering();

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(
            "Test message",
            300_000,
            10
        );

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.resumeGasMetering();
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }

    function testFuzz_conceroSendNativeFee(
        bytes memory payload,
        uint32 gasLimit,
        uint64 srcChainConfirmations
    ) public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(
            payload,
            gasLimit,
            srcChainConfirmations
        );

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }
}
