pragma solidity 0.8.28;

import {BaseMockCLFReport} from "./BaseMockCLFReport.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

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
        return
            getResponse(
                address(operator),
                bytes32("messageId"),
                bytes32("messageHashSum"),
                SRC_CHAIN_SELECTOR,
                DST_CHAIN_SELECTOR,
                address(user),
                RouterTypes.EvmDstChainData({receiver: address(0), gasLimit: 1_000_000}),
                new bytes[](0)
            );
    }

    function getResponse(
        address requester,
        bytes32 messageId,
        bytes32 messageHashSum,
        uint24 srcChainSelector,
        uint24 dstChainSelector,
        address messageSender,
        RouterTypes.EvmDstChainData memory dstChainData,
        bytes[] memory allowedOperators
    ) public view returns (bytes memory) {
        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: requester
        });

        CommonTypes.MessagePayloadV1 memory messagePayload = CommonTypes.MessagePayloadV1({
            messageId: messageId,
            messageHashSum: messageHashSum,
            messageSender: abi.encode(messageSender),
            srcChainSelector: srcChainSelector,
            dstChainSelector: dstChainSelector,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        bytes memory response = abi.encode(resultConfig, abi.encode(messagePayload));
        return response;
    }
}
