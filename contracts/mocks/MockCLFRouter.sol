pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";

interface IMockCLFRouter {
    function setConsumer(address _consumer) external;

    function sendRequest(
        bytes memory data,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external returns (bytes32);

    function transmit(
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes calldata rawVs
    ) external;
}

contract MockCLFRouter {
    error CallFailed();
    event RequestSent(bytes32 indexed id);
    event RequestFulfilled(bytes32 indexed id);
    address public s_consumer; // ConceroVerifier

    function setConsumer(address _consumer) external {
        s_consumer = _consumer;
    }

    // From IFunctionsRouter.sol
    // @notice mocking requests from ConceroVerifier to CLF
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 dataVersion,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external returns (bytes32) {
        bytes32 requestId = keccak256(abi.encodePacked(data, subscriptionId, donId));
        emit RequestSent(requestId);
        return requestId;
    }

    // From FunctionsCoordinator.sol
    // @notice mocking responses from CLF to ConceroVerifier via HandleOracleFulfillment
    function transmit(
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes calldata rawVs
    ) external {
        (
            bytes32[] memory requestIds,
            bytes[] memory results,
            bytes[] memory errors,
            bytes[] memory onchainMetadata,
            bytes[] memory offchainMetadata
        ) = abi.decode(report, (bytes32[], bytes[], bytes[], bytes[], bytes[]));

        bytes32 requestId = requestIds[0];
        bytes memory result = results[0];
        bytes memory err = errors[0];

        (bool success, ) = s_consumer.call(
            abi.encodeWithSignature(
                "handleOracleFulfillment(bytes32,bytes,bytes)",
                requestId,
                result,
                err
            )
        );

        require(success, CallFailed());
        emit RequestFulfilled(requestId);
    }
}
