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
                "dstChain",
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
        bytes memory dstChainData,
        bytes[] memory allowedOperators
    ) public view returns (bytes memory) {
        bytes32 reportConfig = bytes32(
            (uint256(uint8(CommonTypes.CLFReportType.Message)) <<
                ReportConfigBitOffsets.OFFSET_REPORT_TYPE) |
                (uint256(1) << ReportConfigBitOffsets.OFFSET_VERSION) |
                (uint256(uint160(requester)))
        );

        bytes memory messageData = abi.encode(
            messageHashSum,
            abi.encode(messageSender),
            srcChainSelector,
            dstChainSelector,
            dstChainData
        );

        bytes memory messageMetadata = abi.encode(messageId, allowedOperators, messageData);
        bytes memory response = abi.encode(reportConfig, messageMetadata);

        return response;
    }
}
