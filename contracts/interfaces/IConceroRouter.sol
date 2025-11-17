// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

interface IConceroRouter {
    struct MessageRequest {
        uint24 dstChainSelector;
        uint64 srcBlockConfirmations;
        address feeToken;
        address relayerLib;
        address[] validatorLibs;
        bytes[] validatorConfigs;
        bytes relayerConfig;
        bytes dstChainData;
        bytes payload;
    }

    struct Fee {
        uint256 concero;
        uint256 relayer;
        uint256[] validatorsFee;
        address token;
    }

    error InsufficientFee(uint256 provided, uint256 required);
    error UnsupportedFeeToken();
    error PayloadTooLarge(uint256 receivedLength, uint256 expectedLength);
    error EmptyDstChainData();
    error InvalidValidatorsCount(uint256 validatorsCount, uint256 maxValidatorsCount);
    error InvalidValidatorConfigsCount(uint256 validatorConfigsCount, uint256 validatorLibsCount);
    error InvalidGasLimit();

    event ConceroMessageSent(
        bytes32 indexed messageId,
        bytes messageReceipt,
        address[] validatorLibs,
        address relayerLib
    );
    event ConceroMessageFeePaid(bytes32 indexed messageId, Fee fee);
    event ConceroMessageReceived(
        bytes32 indexed messageId,
        bytes messageReceipt,
        bytes[] validations,
        address[] validatorLibs,
        bool[] validationChecks,
        address relayerLib
    );
    event ConceroMessageDelivered(bytes32 indexed messageId);
    event ConceroMessageDeliveryFailed(bytes32 indexed messageId, bytes error);

    /**
     * @notice Concero allows you to send messages from one blockchain
     *         to another using the `conceroSend` function. This enables
     *         cross-chain interactions for a variety of use cases:
     *         token transfers, governance actions, or any custom
     *         cross-chain operations.
     * **/
    function conceroSend(
        MessageRequest calldata messageRequest
    ) external payable returns (bytes32 messageId);

    function retryMessageSubmission(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib,
        uint32 gasLimitOverride
    ) external;

    /**
     * @notice Before sending a message, you must call getMessageFee.
     *         If you choose to pay fees in the native token, pass the
     *         returned value as msg.value.
     */
    function getMessageFee(MessageRequest calldata messageRequest) external view returns (uint256);

    /**
     * @notice Withdraws the Relayer fees earned by the router.
     */
    function withdrawRelayerFee(address[] calldata tokens) external;
}
