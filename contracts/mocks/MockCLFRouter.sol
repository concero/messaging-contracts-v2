pragma solidity 0.8.28;

contract MockCLFRouter {
    error CallFailed();

    struct ClfReport {
        bytes32[] requestIds;
        bytes[] results; // ConceroVerifier:fulfillRequest() gets results[0] as response
        bytes[] errors;
        bytes[] onchainMetadata;
        bytes[] offchainMetadata;
    }

    event RequestSent(
        bytes32 indexed requestId,
        uint64 subscriptionId,
        bytes data,
        uint32 gasLimit,
        bytes32 donId
    );

    address public s_consumer; // ConceroVerifier

    function setConsumer(address _consumer) external {
        s_consumer = _consumer;
    }

    // @notice mocking requests from ConceroVerifier to CLF
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 requestDataVersion,
        uint32 gasLimit,
        bytes32 donId
    ) external returns (bytes32) {
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        emit RequestSent(requestId, subscriptionId, data, gasLimit, donId);
        return requestId;
    }

    // @notice mocking responses from CLF to ConceroVerifier via HandleOracleFulfillment
    function transmit(
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs
    ) external {
        ClfReport memory clfReport = abi.decode(report, (ClfReport));
        bytes32 requestId = clfReport.requestIds[0];
        bytes memory result = clfReport.results[0];
        bytes memory error = clfReport.errors[0];

        (bool success, ) = s_consumer.call(
            abi.encodeWithSignature(
                "handleOracleFulfillment(bytes32,bytes,bytes)",
                requestId,
                result,
                error
            )
        );

        require(success, CallFailed());
    }
}
