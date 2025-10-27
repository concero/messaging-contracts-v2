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
        bytes[] validationRpcs;
        bytes[] deliveryRpcs;
        bytes dstChainData;
        bytes payload;
    }

    struct MessageReceipt {
        uint24 srcChainSelector;
        uint24 dstChainSelector;
        bytes srcChainData;
        bytes dstChainData;
        bytes dstRelayerLib; // TODO: mb should be bytes32
        bytes relayerConfig;
        bytes[] dstValidatorLibs;
        bytes[] validatorConfigs;
        bytes[] validationRpcs;
        bytes[] deliveryRpcs;
        bytes payload;
    }

    struct EvmSrcChainData {
        uint64 blockConfirmations;
        address sender;
    }

    struct EvmDstChainData {
        address receiver;
        uint256 gasLimit;
    }

    struct Fee {
        uint256 concero;
        uint256 relayer;
        address token;
    }

    enum RequiredVariableUnsetType {
        NativeUSDRate,
        lastGasPrice
    }

    error InsufficientFee(uint256 provided, uint256 required);
    error RequiredVariableUnset(RequiredVariableUnsetType variableType);
    error UnsupportedFeeToken();
    error MessageTooLarge(uint256 receviedLength, uint256 expectedLength);
    error EmptyDstChainData();

    event ConceroMessageSent(bytes32 indexed messageId, MessageReceipt messageReceipt);
    event ConceroMessageFeePaid(bytes32 indexed messageId, Fee fee);
    event ConceroMessageReceived(
        bytes32 indexed messageId,
        MessageReceipt messageReceipt,
        bytes[] validations,
        bool[] validationChecks
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

    /**
     * @notice Before sending a message, you must call getMessageFee.
     *         If you choose to pay fees in the native token, pass the
     *         returned value as msg.value.
     */
    function getMessageFee(MessageRequest calldata messageRequest) external view returns (uint256);
}
