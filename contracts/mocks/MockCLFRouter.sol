pragma solidity 0.8.28;

contract MockCLFRouter {
    event RequestSent(
        bytes32 indexed requestId,
        uint64 subscriptionId,
        bytes data,
        uint32 gasLimit,
        bytes32 donId
    );

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

    function fulfillRequest(bytes32 requestId, bytes memory response) external {
        // Implementation for test responses
    }
}
