// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroClient} from "../../../contracts/ConceroClient/ConceroClient.sol";
import {IRelayer} from "../../../contracts/interfaces/IRelayer.sol";
import {IConceroRouter} from "../../../contracts/interfaces/IConceroRouter.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {MessageCodec} from "../../../contracts/common/libraries/MessageCodec.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AttackingConceroClient is ConceroClient {
    using MessageCodec for bytes;
    using MessageCodec for IConceroRouter.MessageRequest;

    address internal immutable i_validatorLib;
    address internal immutable i_relayerLib;

    uint256 internal s_reentrantCounter;
    bool internal s_isRevertMod;

    constructor(
        address conceroRouter,
        address validatorLib,
        address relayerLib
    ) ConceroClient(conceroRouter) {
        i_validatorLib = validatorLib;
        i_relayerLib = relayerLib;

        _setIsRelayerAllowed(i_relayerLib, true);
        _setIsValidatorAllowed(i_validatorLib, true);
        _setRequiredValidatorsCount(1);
    }

    function _conceroReceive(bytes calldata messageReceipt) internal override {
        require(!s_isRevertMod, "revert");

        ++s_reentrantCounter;

        if (s_reentrantCounter > 1) {
            return;
        }

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = i_validatorLib;
        bytes[] memory validations = new bytes[](1);
        validations[0] = new bytes(1);

        if (keccak256(messageReceipt.payload()) == keccak256("submit")) {
            IRelayer(i_conceroRouter).submitMessage(
                messageReceipt,
                validations,
                validatorLibs,
                i_relayerLib
            );
        } else if (keccak256(messageReceipt.payload()) == keccak256("retry")) {
            bool[] memory validationChecks = new bool[](1);
            validationChecks[0] = true;

            IConceroRouter(i_conceroRouter).retryMessageSubmission(
                messageReceipt,
                validationChecks,
                validatorLibs,
                i_relayerLib,
                1_000_000
            );
        }
    }

    function getCounter() public view returns (uint256) {
        return s_reentrantCounter;
    }

    function setIsRevertMod(bool isRevert) public {
        s_isRevertMod = isRevert;
    }
}

contract ConceroRouterReentrancyAttack is ConceroRouterTest {
    using MessageCodec for bytes;
    using MessageCodec for IConceroRouter.MessageRequest;

    AttackingConceroClient internal s_attackingConceroClient;

    function setUp() public override {
        super.setUp();

        s_attackingConceroClient = new AttackingConceroClient(
            address(s_conceroRouter),
            s_validatorLib,
            s_relayerLib
        );
    }

    function test_reentrantSubmitMessage() public {
        (bytes memory messageReceipt, bytes[] memory validations) = _buildMessageSubmission(
            "submit"
        );

        s_conceroRouter.submitMessage(messageReceipt, validations, s_validatorLibs, s_relayerLib);

        assert(s_attackingConceroClient.getCounter() == 0);
    }

    function test_resubmitMessageInRetry() public {
        (bytes memory messageReceipt, bytes[] memory validations) = _buildMessageSubmission(
            "submit"
        );

        s_attackingConceroClient.setIsRevertMod(true);
        s_conceroRouter.submitMessage(messageReceipt, validations, s_validatorLibs, s_relayerLib);
        s_attackingConceroClient.setIsRevertMod(false);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        s_conceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            s_validatorLibs,
            s_relayerLib,
            1_000_000
        );

        assert(s_attackingConceroClient.getCounter() == 0);
    }

    function test_retryMessageInRetry() public {
        (bytes memory messageReceipt, bytes[] memory validations) = _buildMessageSubmission(
            "retry"
        );

        s_attackingConceroClient.setIsRevertMod(true);
        s_conceroRouter.submitMessage(messageReceipt, validations, s_validatorLibs, s_relayerLib);
        s_attackingConceroClient.setIsRevertMod(false);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        s_conceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            s_validatorLibs,
            s_relayerLib,
            1_000_000
        );

        assert(s_attackingConceroClient.getCounter() == 0);
    }

    // HELPERS

    function _buildMessageSubmission(
        bytes memory payload
    ) internal returns (bytes memory, bytes[] memory) {
        IConceroRouter.MessageRequest memory messageRequest = IConceroRouter.MessageRequest({
            dstChainSelector: SRC_CHAIN_SELECTOR,
            srcBlockConfirmations: 3,
            feeToken: address(0),
            relayerLib: s_relayerLib,
            validatorLibs: s_validatorLibs,
            relayerConfig: new bytes(0),
            validatorConfigs: s_validatorConfigs,
            dstChainData: MessageCodec.encodeEvmDstChainData(
                address(s_attackingConceroClient),
                2_000_000
            ),
            payload: payload
        });

        bytes memory messageReceipt = messageRequest.toMessageReceiptBytes(
            DST_CHAIN_SELECTOR,
            address(this),
            1
        );

        bytes[] memory validations = new bytes[](1);
        validations[0] = new bytes(1);

        return (messageReceipt, validations);
    }
}
