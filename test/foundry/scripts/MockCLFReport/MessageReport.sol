pragma solidity 0.8.28;

import {BaseMockCLFReport} from "./BaseMockCLFReport.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {Types as RouterTypes} from "../../../../contracts/ValidatorLib/libraries/Types.sol";

contract MessageReport is BaseMockCLFReport {
    function getReport() public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return getReport(getResponse(), bytes32("requestId"));
    }

    function getReport(
        bytes32 clfRequestId
    ) public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return getReport(getResponse(), clfRequestId);
    }

    function getReport(
        bytes memory expectedResponse,
        bytes32 clfRequestId
    ) public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return createMockClfReport(expectedResponse, clfRequestId);
    }

    function getResponse() public view returns (bytes memory) {
        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);
        return
            getResponse(
                address(operator),
                bytes32("messageId"),
                bytes32("messageHashSum"),
                bytes32("txHash"),
                SRC_CHAIN_SELECTOR,
                DST_CHAIN_SELECTOR,
                address(user),
                12345678, // Default block number
                RouterTypes.EvmDstChainData({receiver: address(0), gasLimit: 1_000_000}),
                allowedOperators
            );
    }

    function getResponse(
        address requester,
        bytes32 messageId,
        bytes32 messageHashSum,
        bytes32 txHash,
        uint24 srcChainSelector,
        uint24 dstChainSelector,
        address messageSender,
        uint256 srcBlockNumber,
        RouterTypes.EvmDstChainData memory dstChainData,
        bytes[] memory allowedOperators
    ) public pure returns (bytes memory) {
        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: requester
        });

        CommonTypes.MessagePayloadV1 memory messagePayload = CommonTypes.MessagePayloadV1({
            messageId: messageId,
            messageHashSum: messageHashSum,
            txHash: txHash,
            messageSender: abi.encode(messageSender),
            srcChainSelector: srcChainSelector,
            dstChainSelector: dstChainSelector,
            srcBlockNumber: srcBlockNumber,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        //        CommonTypes.VerifierResult memory response = CommonTypes.VerifierResult({
        //            resultConfig: resultConfig,
        //            payload: abi.encode(messagePayload)
        //        });

        bytes memory response = abi.encode(resultConfig, abi.encode(messagePayload));
        return response;
    }
}
